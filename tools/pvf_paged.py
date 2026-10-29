"""Read-only paged NKPI PVF reader using the matching, locally supplied client.

Format facts: 10 MiB pages with a 10 KiB AES-CBC guard, sealed page table in
sk.dat, 24-byte file records, two string pools, and zlib body groups. Checked
against the documented format in MaiKuraki/DFO_pvfine/internal/pvf; this module
is independently implemented and does not bundle client keys or executables.
"""
from collections import OrderedDict
import re
import struct
import zlib

PAGE = 10 * 1024 * 1024
GUARD = 10 * 1024
LIMIT = 256 * 1024 * 1024
MASK = 0xFFFFFFFF
PEM = re.compile(rb'-----BEGIN (?:RSA )?PRIVATE KEY-----[\s\S]{1,8192}?-----END (?:RSA )?PRIVATE KEY-----')
HEX = re.compile(rb'(?<![0-9a-fA-F])[0-9a-fA-F]{64}(?![0-9a-fA-F])')


def aes_decode(data, key):
    from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
    decoder = Cipher(algorithms.AES(key), modes.CBC(bytes(16))).decryptor()
    return decoder.update(data) + decoder.finalize()


def section(data, name, increment=0x269EC3):
    codes = list(name.encode('utf-16-le'))[::2]
    state = (0x339E9711 * codes[0] + sum(codes[i] * 0x393 ** (4 - i) for i in range(1, 4))) & MASK
    result = bytearray(data)
    for offset in range(0, len(data), 4):
        first = (0x343FD * state + increment) & MASK
        state = (0x343FD * first + increment) & MASK
        stream = struct.pack('<I', (first & 0xFFFF0000) | (state >> 16))
        for i in range(min(4, len(data) - offset)):
            result[offset + i] ^= stream[i]
    return bytes(result)


def client_material(stream):
    """Scan only the supplied game executable; never print or export key values."""
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.asymmetric.rsa import RSAPrivateKey
    seen_pem, metadata, keys = set(), set(), []
    tail = b''
    while True:
        block = stream.read(1024 * 1024)
        if not block:
            break
        window = tail + block
        for match in PEM.finditer(window):
            value = match.group()
            if value in seen_pem:
                continue
            seen_pem.add(value)
            try:
                key = serialization.load_pem_private_key(value, password=None)
                if isinstance(key, RSAPrivateKey):
                    keys.append(key)
            except ValueError:
                pass
        metadata.update(bytes.fromhex(m.group().decode('ascii')) for m in HEX.finditer(window))
        if len(metadata) > 4096 or len(keys) > 64:
            raise ValueError('Unexpected client material count; refusing an unbounded search')
        tail = window[-16384:]
    return keys, metadata


def header_fields(plain, size):
    if len(plain) != 48 or plain[:4] != b'nkpi':
        return None
    words = struct.unpack('<12I', plain)
    count, body, groups, hashes, names = words[6], words[8], words[9], words[10], words[11]
    if not (0 < count <= 2_000_000 and 0 < groups < 100_000 and 0 < names <= LIMIT and hashes > 0):
        return None
    if 48 + count * 24 + hashes + names + groups * 8 + body != size:
        return None
    return dict(format='paged-nkpi', files=count, groups=groups, body_bytes=body, hash_bytes=hashes, names_bytes=names)


def unlock(header, size, sealed, keys, metadata):
    from cryptography.hazmat.primitives.asymmetric import padding
    required = (size + PAGE - 1) // PAGE * 32
    for key in keys:
        block = key.key_size // 8
        if len(sealed) % block:
            continue
        try:
            wrapped = b''.join(key.decrypt(sealed[i:i + block], padding.PKCS1v15()) for i in range(0, len(sealed), block))
        except ValueError:
            continue
        if len(wrapped) % 32 or len(wrapped) < required:
            continue
        aligned = len(wrapped) // 256 * 256
        if not aligned:
            continue
        for candidate in metadata:
            table = aes_decode(wrapped[:aligned], candidate) + wrapped[aligned:]
            plain = section(aes_decode(header, table[:32]), 'iNfO')
            fields = header_fields(plain, size)
            if fields:
                return table, fields
    raise ValueError(f'No matching client material validated the PVF header ({len(keys)} RSA candidates, {len(metadata)} metadata candidates). No action files were exported.')


def inflate(data, expected):
    if not 0 <= expected <= LIMIT:
        raise ValueError('Unsupported decompressed section size')
    decoder = zlib.decompressobj()
    result = decoder.decompress(data, expected + 1)
    if len(result) != expected or not decoder.eof:
        raise ValueError('PVF compressed section failed size/checksum validation')
    return result


class PagedPVF:
    def __init__(self, stream, size, sealed, keys, metadata):
        self.stream, self.size = stream, size
        stream.seek(0)
        self.pages, self.header = unlock(stream.read(48), size, sealed, keys, metadata)
        self.guards = OrderedDict()
        self.cached_group = None
        count = self.header['files']
        print(f'Validated paged PVF: {count} file records. Reading reference metadata.', flush=True)
        table = self.read_at(48, count * 24)
        names_offset = 48 + count * 24 + self.header['hash_bytes']
        encoded = self.read_at(names_offset, self.header['names_bytes'])
        print('Decoding the name pools for action lookup.', flush=True)
        self.pools = []
        cursor = 8
        for key, mask in (('stAs', 3886938090), ('stWs', 3101599660)):
            if cursor + 8 > len(encoded):
                raise ValueError('Truncated name-pool header')
            first, second = struct.unpack_from('<2I', encoded, cursor)
            cursor += 8
            length = first ^ mask
            expected = second ^ length
            if length == expected == 0:
                self.pools.append(b'')
                continue
            if not 0 < length <= len(encoded) - cursor:
                raise ValueError('Invalid name-pool extent')
            self.pools.append(inflate(section(encoded[cursor:cursor + length], key, 0x269EC9), expected))
            cursor += length
        group_offset = names_offset + len(encoded)
        groups = section(self.read_at(group_offset, self.header['groups'] * 8), 'Gidx')
        self.group_index = list(struct.iter_unpack('<2I', groups))
        previous = 0
        for compressed, original in self.group_index:
            if compressed <= previous or compressed > self.header['body_bytes'] or original > LIMIT:
                raise ValueError('Invalid compressed-group index')
            previous = compressed
        if previous != self.header['body_bytes']:
            raise ValueError('Body size differs from the final group boundary')
        self.body_offset = group_offset + len(groups)
        print('Resolving action filenames.', flush=True)
        self.entries = []
        classes = ('swordman', 'gunner', 'fighter', 'mage', 'priest')
        for name, directory, group, offset, length, kind in struct.iter_unpack('<6I', table):
            path = (self.resolve(directory).rstrip('/') + '/' + self.resolve(name)).replace('\\', '/').lower().lstrip('/')
            if not path.startswith(tuple(f'character/{c}/' for c in classes)) or not path.endswith(('.ani', '.chr')):
                continue
            if '..' in path.split('/') or group >= len(self.group_index) or offset + length > self.group_index[group][1]:
                raise ValueError('Invalid action entry or group boundary')
            self.entries.append(dict(path=path, size=length, padded=length, offset=offset, group=group, data_type=kind))
        print(f'Found {len(self.entries)} character animation/configuration entries.', flush=True)

    def resolve(self, value):
        wide = value & 1
        pool = self.pools[wide]
        start = (value >> 1) * (2 if wide else 1)
        if not pool and start == 0:
            return ''
        if start >= len(pool):
            raise ValueError('String reference exceeds its pool')
        if wide:
            end = start
            while end + 1 < len(pool) and pool[end:end + 2] != b'\0\0':
                end += 2
            return pool[start:end].decode('utf-16-le', errors='replace')
        end = pool.find(b'\0', start)
        return pool[start:end if end >= 0 else len(pool)].decode('utf-8', errors='replace')

    def read_at(self, start, size):
        if start < 0 or size < 0 or start + size > self.size:
            raise ValueError('Read outside the PVF archive')
        output = bytearray()
        while size:
            page, local = divmod(start, PAGE)
            if local < GUARD:
                if page not in self.guards:
                    self.stream.seek(page * PAGE)
                    raw = self.stream.read(GUARD)
                    if len(raw) != GUARD:
                        raise ValueError('Truncated page guard')
                    self.guards[page] = aes_decode(raw, self.pages[page * 32:(page + 1) * 32])
                    if len(self.guards) > 2:
                        self.guards.popitem(last=False)
                amount = min(size, GUARD - local)
                output.extend(self.guards[page][local:local + amount])
            else:
                amount = min(size, PAGE - local)
                self.stream.seek(start)
                raw = self.stream.read(amount)
                if len(raw) != amount:
                    raise ValueError('Truncated archive extent')
                output.extend(raw)
            start += amount
            size -= amount
        return bytes(output)

    def read(self, entry):
        group = entry['group']
        if self.cached_group is None or self.cached_group[0] != group:
            previous = self.group_index[group - 1][0] if group else 0
            end, original = self.group_index[group]
            raw = self.read_at(self.body_offset + previous, end - previous)
            self.cached_group = (group, inflate(section(raw, 'mAIn'), original))
        data = self.cached_group[1]
        return data[entry['offset']:entry['offset'] + entry['size']]

    def support_files(self):
        for label, pool in zip(('utf8', 'utf16'), self.pools):
            if pool:
                yield f'pools/{label}.zlib', zlib.compress(pool, 9)
