"""Exercise selective action extraction on an independently assembled PVF fixture."""
from pathlib import Path
import importlib.util
import io
import struct
import tempfile
import unittest
import zipfile

spec = importlib.util.spec_from_file_location('pvf_actions', Path(__file__).resolve().parents[2] / 'tools/extract-dfo-action-reference.py')
pvf = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pvf)


def encrypted(data, seed):
    data += b'\0' * (-len(data) % 4)
    output = bytearray()
    for (word,) in struct.iter_unpack('<I', data):
        value = ((word << 6) | (word >> 26)) & 0xFFFFFFFF
        output.extend(struct.pack('<I', value ^ seed ^ 0x81A79011))
    return bytes(output)


def fixture():
    files = {
        'character/swordman/animation/run.ani': b'run frame reference',
        'character/fighter/animation/attack1.ani': b'attack frame reference',
        'character/priest/priest.chr': b'character action links',
        'character/atswordman/animation/run.ani': b'wrong roster variant',
        'character/mage/animation/fireball/nested.ani': b'unrelated effect',
        'stringtable.bin': b'string lookup fixture',
    }
    tree, content = bytearray(), bytearray()
    for i, (name, data) in enumerate(files.items()):
        path = name.encode();seed = 100 + i
        tree.extend(struct.pack('<2I', i, len(path)) + path + struct.pack('<3I', len(data), seed, len(content)))
        content.extend(encrypted(data, seed))
    encoded = encrypted(bytes(tree), 12345)
    header = struct.pack('<I', 36) + b'0' * 36 + struct.pack('<4I', 1, len(encoded), 12345, len(files))
    return header + encoded + content, files


class PVFActionsTests(unittest.TestCase):
    def test_extracts_only_selected_roster_actions_without_full_unpack(self):
        data, files = fixture()
        with tempfile.TemporaryDirectory() as directory:
            archive = Path(directory) / 'DFO.zip';output = Path(directory) / 'reference.zip'
            with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
                z.writestr('DFO/Script.pvf', data)
                z.writestr('DFO/large-unrelated-file', b'untouched')
            pvf.extract(archive, output)
            with zipfile.ZipFile(output) as z:
                self.assertEqual(z.read('character/swordman/animation/run.ani'), files['character/swordman/animation/run.ani'])
                self.assertEqual(z.read('character/fighter/animation/attack1.ani'), files['character/fighter/animation/attack1.ani'])
                self.assertEqual(z.read('stringtable.bin'), files['stringtable.bin'])
                self.assertNotIn('character/atswordman/animation/run.ani', z.namelist())
                self.assertNotIn('character/mage/animation/fireball/nested.ani', z.namelist())

    def test_rejects_unknown_header_and_truncated_payload(self):
        with self.assertRaises(ValueError):
            pvf.PVF(io.BytesIO(struct.pack('<I', 999)), 4)
        data, _ = fixture()
        with self.assertRaises(ValueError):
            pvf.PVF(io.BytesIO(data), len(data) - 32)


if __name__ == '__main__':
    unittest.main()
