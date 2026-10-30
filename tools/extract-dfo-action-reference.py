"""Read basic animation definitions from Script.pvf inside DFO.zip, without unpacking the game.

Container layout cross-checked against Zageku/DNF_pvf_python's pvfReader.py:
https://github.com/Zageku/DNF_pvf_python/blob/main/dnfpkgtool/pvfReader.py
Only container parsing is implemented here; game scripts are never executed.
"""
import argparse
from array import array
import json
from pathlib import Path, PurePosixPath
import re
import struct
import sys
import zipfile

CLASSES = ('swordman', 'gunner', 'fighter', 'mage', 'priest')
BASIC = re.compile(r'^(stand|walk|run|attack|atk|dash|jump|land|sit|damage|down|move|hurt|guard|rest)', re.I)


def decrypt(raw, seed):
    if len(raw) % 4:
        raise ValueError('Encrypted block is not word-aligned')
    words = array('I')
    words.frombytes(raw)
    if sys.byteorder != 'little':
        words.byteswap()
    key = seed ^ 0x81A79011
    for i, word in enumerate(words):
        value = word ^ key
        words[i] = ((value >> 6) | (value << 26)) & 0xFFFFFFFF
    if sys.byteorder != 'little':
        words.byteswap()
    return words.tobytes()


def read_exact(stream, size):
    data = stream.read(size)
    if len(data) != size:
        raise ValueError('Truncated PVF data')
    return data


class PVF:
    def __init__(self, stream, size):
        self.stream = stream
        uuid_size = struct.unpack('<I', read_exact(stream, 4))[0]
        if not 1 <= uuid_size <= 128:
            raise ValueError('Unsupported PVF header; UUID size is outside the known format')
        uuid = read_exact(stream, uuid_size)
        version, tree_size, seed, count = struct.unpack('<4I', read_exact(stream, 16))
        self.header = dict(uuid=uuid.decode('ascii', errors='replace'), version=version, tree_bytes=tree_size, files=count)
        if tree_size > min(size, 128 * 1024 * 1024) or count > 2_000_000:
            raise ValueError('Unsupported PVF index size')
        tree = decrypt(read_exact(stream, tree_size), seed)
        self.data_start = stream.tell()
        self.entries = []
        cursor = 0
        for _ in range(count):
            if cursor + 8 > len(tree):
                raise ValueError('Invalid decrypted file index')
            _, name_size = struct.unpack_from('<2I', tree, cursor)
            cursor += 8
            if not 1 <= name_size <= 4096 or cursor + name_size + 12 > len(tree):
                raise ValueError('This PVF file uses a different index format')
            name = tree[cursor:cursor + name_size].decode('utf-8', errors='replace').replace('\\', '/').lower().lstrip('/')
            cursor += name_size
            length, crc, offset = struct.unpack_from('<3I', tree, cursor)
            cursor += 12
            padded = (length + 3) & ~3
            if '..' in PurePosixPath(name).parts or self.data_start + offset + padded > size:
                raise ValueError('Invalid PVF path or content offset')
            self.entries.append(dict(path=name, size=length, padded=padded, seed=crc, offset=offset))

    def read(self, entry):
        self.stream.seek(self.data_start + entry['offset'])
        return decrypt(read_exact(self.stream, entry['padded']), entry['seed'])[:entry['size']]


def is_action(entry):
    name = entry['path']
    parts = name.split('/')
    if len(parts) < 3 or parts[0] != 'character' or parts[1] not in CLASSES:
        return False
    tail = '/'.join(parts[2:])
    if name.endswith('.chr'):
        return True
    if not name.endswith('.ani'):
        return False
    # Include root animation files, plus named basic actions in nested folders.
    return (tail.startswith('animation/') and '/' not in tail[len('animation/'):]) or bool(BASIC.match(parts[-1]))


def extract(archive, output):
    with zipfile.ZipFile(archive) as outer:
        info = next((i for i in outer.infolist() if i.filename.lower().endswith('/script.pvf') or i.filename.lower() == 'script.pvf'), None)
        if info is None:
            raise ValueError('Script.pvf was not found inside DFO.zip')
        print('Reading the PVF directory in place; the 44 GB game will not be extracted.', flush=True)
        with outer.open(info) as stream:
            probe = read_exact(stream, 4)
            stream.seek(0)
            if 1 <= struct.unpack('<I', probe)[0] <= 128:
                pvf = PVF(stream, info.file_size)
            else:
                from pvf_paged import PagedPVF, client_material
                parent = info.filename.rsplit('/', 1)[0] if '/' in info.filename else ''
                siblings = {i.filename.lower().rsplit('/', 1)[-1]: i for i in outer.infolist()
                            if (i.filename.rsplit('/', 1)[0] if '/' in i.filename else '') == parent}
                executable = siblings.get('dfo.exe') or siblings.get('dnf.exe')
                sidecar = siblings.get('sk.dat')
                if executable is None or sidecar is None or sidecar.file_size > 65536:
                    raise ValueError('Paged PVF requires its matching sk.dat and DFO.exe in the same archive folder')
                print('Reading matching client metadata from DFO.exe inside the ZIP; the executable is not run or exported.', flush=True)
                with outer.open(executable) as client:
                    keys, metadata = client_material(client)
                print('Client scan complete. Validating matching archive metadata.', flush=True)
                try:
                    pvf = PagedPVF(stream, info.file_size, outer.read(sidecar), keys, metadata)
                except Exception as error:
                    error.input_members = [dict(path=item.filename, bytes=item.file_size, crc32=f'{item.CRC:08x}')
                                           for item in (info, executable, sidecar)]
                    raise
            candidates = [e for e in pvf.entries if is_action(e)]
            # Reserve the small core actions across all five classes before extras.
            def priority(entry):
                stem = PurePosixPath(entry['path']).stem
                core = bool(re.fullmatch(r'(stand|walk|run|attack|atk)[0-9]*', stem))
                return (0 if entry['path'].endswith('.chr') or core else 1, entry['path'])
            candidates.sort(key=priority)
            selected = []
            total = 0
            for entry in candidates:
                if entry['size'] <= 1024 * 1024 and total + entry['padded'] <= 8 * 1024 * 1024:
                    selected.append(entry)
                    total += entry['padded']
            strings = next((e for e in pvf.entries if e['path'] == 'stringtable.bin'), None)
            if strings and strings['size'] <= 20 * 1024 * 1024:
                selected.append(strings)
            if not candidates:
                error = ValueError('No basic character ANI definitions found in this PVF version')
                error.action_paths = [e['path'] for e in pvf.entries if e['path'].endswith(('.ani', '.chr'))][:5000]
                error.lookup_warnings = getattr(pvf, 'lookup_warnings', None)
                raise error
            index = [dict(path=e['path'], bytes=e['size']) for e in pvf.entries if e['path'].startswith(tuple(f'character/{c}/' for c in CLASSES)) and e['path'].endswith(('.ani', '.chr'))]
            print(f'Exporting {len(selected)} selected action/reference files.', flush=True)
            with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as dest:
                dest.writestr('reference-index.json', json.dumps(dict(header=pvf.header, selected=[e['path'] for e in selected], available=index, lookup_warnings=getattr(pvf, 'lookup_warnings', None)), indent=2))
                for entry in sorted(selected, key=lambda e: (e.get('group', 0), e['offset'])):
                    dest.writestr(entry['path'], pvf.read(entry))
                if hasattr(pvf, 'support_files'):
                    for name, data in pvf.support_files():
                        dest.writestr(name, data, compress_type=zipfile.ZIP_STORED)
    if Path(output).stat().st_size >= 32 * 1024 * 1024:
        parts = []
        with Path(output).open('rb') as source:
            while data := source.read(24 * 1024 * 1024):
                part = Path(str(output) + f'.part{len(parts) + 1:02}')
                part.write_bytes(data)
                parts.append(part.name)
        Path(output).unlink()
        print('Reference is split into uploadable parts: ' + ', '.join(parts), flush=True)
        print('Upload all of these parts together in our chat.', flush=True)
        return
    print(f'Created {output} ({Path(output).stat().st_size / 1024 / 1024:.1f} MiB)', flush=True)
    print('Upload this reference ZIP in our chat. No need to upload the whole PVF or executable.', flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive', type=Path, default=Path.home() / 'Documents/DFO.zip')
    parser.add_argument('--output', type=Path, default=Path.home() / 'Documents/DFO-action-reference.zip')
    args = parser.parse_args()
    if args.output.parent == Path('/output'):
        print('Output folder on your Mac: Documents/DFO-action-reference', flush=True)
    print('Action reference helper: diagnostic version 3', flush=True)
    try:
        extract(args.archive, args.output)
    except Exception as error:
        report = args.output.with_name('DFO-action-diagnostic.zip')
        with zipfile.ZipFile(report, 'w', zipfile.ZIP_DEFLATED) as dest:
            dest.writestr('diagnostic.json', json.dumps(dict(error=str(error),available_action_paths=getattr(error, 'action_paths', None),validation=getattr(error, 'validation', None), input_members=getattr(error, 'input_members', None), lookup_warnings=getattr(error, 'lookup_warnings', None), diagnostic_version=3, note='No original game files were modified. PVF variant needs inspection.'), indent=2))
            try:
                with zipfile.ZipFile(args.archive) as outer:
                    member = next(i for i in outer.infolist() if i.filename.lower().endswith('/script.pvf') or i.filename.lower() == 'script.pvf')
                    with outer.open(member) as source:
                        dest.writestr('pvf-header-sample.bin', source.read(65536))
            except Exception:
                pass
        print(f'Could not read this PVF variant: {error}\nUpload {report} instead.', file=sys.stderr)
        raise SystemExit(1)
