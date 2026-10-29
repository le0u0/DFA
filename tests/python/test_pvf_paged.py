"""Independent encrypted-container fixtures; no real game key material is stored."""
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest
import zipfile
import zlib
from collections import OrderedDict
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'tools'))
import pvf_paged as reader


def encrypted(data, key):
    cipher = Cipher(algorithms.AES(key), modes.CBC(bytes(16))).encryptor()
    return cipher.update(data) + cipher.finalize()


def fixture():
    private = rsa.generate_private_key(public_exponent=65537, key_size=1024)
    pem = private.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption())
    metadata = hashlib.sha256(b'public synthetic test metadata').digest()
    table = b''.join(hashlib.sha256(b'fixture page' + bytes([i])).digest() for i in range(8))
    wrapped = encrypted(table, metadata)
    sealed = b''.join(private.public_key().encrypt(wrapped[i:i + 117], padding.PKCS1v15()) for i in range(0, len(wrapped), 117))
    wide = bytearray(b'\0\0')
    def string(value):
        offset = len(wide) | 1
        wide.extend(value.encode('utf-16-le') + b'\0\0')
        return offset
    name, directory = string('run.ani'), string('character/swordman/animation')
    pool = reader.section(zlib.compress(wide), 'stWs', 0x269EC9)
    names = bytes(8) + struct.pack('<2I', 3886938090, 0) + struct.pack('<2I', len(pool) ^ 3101599660, len(wide) ^ len(pool)) + pool
    payload = b'run frame fixture'
    filler = b''.join(hashlib.sha256(struct.pack('<I', i)).digest() for i in range(420))
    group = payload + filler
    body = reader.section(zlib.compress(group), 'mAIn')
    file_table = struct.pack('<6I', name, directory, 0, 0, len(payload), 2)
    groups = reader.section(struct.pack('<2I', len(body), len(group)), 'Gidx')
    words = [0x69706B6E, 0, 0, 0, 0, 0, 1, 0, len(body), 1, 4, len(names)]
    header = reader.section(struct.pack('<12I', *words), 'iNfO')
    plain = header + file_table + bytes(4) + names + groups + body
    assert len(plain) > reader.GUARD
    archive = encrypted(plain[:reader.GUARD], table[:32]) + plain[reader.GUARD:]
    exe = b'MZ fixture, never executable\0' + pem + b'\0' + metadata.hex().encode() + b'\0'
    return archive, sealed, exe, payload, wide, table


class PagedTests(unittest.TestCase):
    def test_validates_matching_client_and_extracts_payload(self):
        archive, sealed, exe, payload, wide, _ = fixture()
        keys, metadata = reader.client_material(io.BytesIO(exe))
        source = reader.PagedPVF(io.BytesIO(archive), len(archive), sealed, keys, metadata)
        self.assertEqual(source.header['format'], 'paged-nkpi')
        self.assertEqual(source.entries[0]['path'], 'character/swordman/animation/run.ani')
        self.assertEqual(source.read(source.entries[0]), payload)
        support = dict(source.support_files())
        self.assertEqual(zlib.decompress(support['pools/utf16.zlib']), wide)

    def test_wrong_metadata_cannot_produce_action_data(self):
        archive, sealed, exe, _, _, _ = fixture()
        keys, _ = reader.client_material(io.BytesIO(exe))
        with self.assertRaisesRegex(ValueError, 'No matching client material'):
            reader.PagedPVF(io.BytesIO(archive), len(archive), sealed, keys, {bytes(32)})

    def test_failure_reports_stage_without_exporting_key_material(self):
        archive, sealed, exe, _, _, table = fixture()
        keys, metadata = reader.client_material(io.BytesIO(exe))
        with self.assertRaises(ValueError) as failure:
            reader.unlock(archive[:48], len(archive), sealed, keys, {bytes(32)})
        report = failure.exception.validation
        check = report['rsa'][0]
        self.assertEqual(check['stage'], 'header_validation_failed')
        self.assertEqual(check['unsealed_bytes'], len(table))
        self.assertEqual(check['decrypted_blocks'], len(sealed) // 128)
        self.assertEqual(check['header_checks'], [dict(signature_matches=False)])
        encoded = json.dumps(report)
        self.assertNotIn(table.hex(), encoded)
        self.assertNotIn(next(iter(metadata)).hex(), encoded)
        self.assertNotIn('PRIVATE KEY', encoded)

    def test_failure_distinguishes_sidecar_block_size_from_header_failure(self):
        archive, sealed, exe, _, _, _ = fixture()
        keys, metadata = reader.client_material(io.BytesIO(exe))
        with self.assertRaises(ValueError) as failure:
            reader.unlock(archive[:48], len(archive), sealed[:-1], keys, metadata)
        check = failure.exception.validation['rsa'][0]
        self.assertEqual(check['stage'], 'sidecar_not_block_aligned')
        self.assertEqual(check['decrypted_blocks'], 0)

    def test_reads_across_an_encrypted_page_boundary(self):
        _, _, _, _, _, keys = fixture()
        size = reader.PAGE + reader.GUARD + 64
        plain = (bytes(range(256)) * ((size + 255) // 256))[:size]
        raw = bytearray(plain)
        for page in range(2):
            start = page * reader.PAGE
            raw[start:start + reader.GUARD] = encrypted(plain[start:start + reader.GUARD], keys[page * 32:page * 32 + 32])
        source = reader.PagedPVF.__new__(reader.PagedPVF)
        source.stream, source.size, source.pages, source.guards = io.BytesIO(raw), size, keys, OrderedDict()
        start, count = reader.PAGE - 16, reader.GUARD + 32
        self.assertEqual(source.read_at(start, count), plain[start:start + count])

    def test_whole_zip_workflow_never_exports_executable_or_keys(self):
        archive, sealed, exe, payload, _, _ = fixture()
        path = Path(__file__).resolve().parents[2] / 'tools/extract-dfo-action-reference.py'
        spec = importlib.util.spec_from_file_location('paged_extract', path)
        module = importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as directory:
            original = Path(directory) / 'DFO.zip';output = Path(directory) / 'actions.zip'
            with zipfile.ZipFile(original, 'w', zipfile.ZIP_DEFLATED) as packed:
                for name, data in [('DFO/Script.pvf', archive), ('DFO/sk.dat', sealed), ('DFO/DFO.exe', exe)]:packed.writestr(name, data)
            module.extract(original, output)
            with zipfile.ZipFile(output) as packed:
                self.assertEqual(packed.read('character/swordman/animation/run.ani'), payload)
                self.assertFalse(any(n.endswith(('.exe', '.dat', '.pem')) for n in packed.namelist()))


if __name__ == '__main__':
    unittest.main()
