"""Regression cases for cross-cell feet/hair contamination in generated atlases."""
from pathlib import Path
import sys
import unittest
from PIL import Image, ImageDraw
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'tools'))
from sprite_cells import isolate_cell


class SpriteCellTests(unittest.TestCase):
    def fixture(self):
        image = Image.new('RGBA', (64, 64))
        draw = ImageDraw.Draw(image)
        draw.rectangle((12, 10, 42, 60), fill=(230, 140, 70, 255))
        # A legitimate connected attack hand reaches the cell edge.
        draw.rectangle((40, 20, 63, 26), fill=(230, 140, 70, 255))
        # Previous row's feet, disconnected above the character's head.
        draw.rectangle((15, 0, 27, 2), fill=(10, 10, 10, 255))
        draw.rectangle((35, 0, 45, 2), fill=(10, 10, 10, 255))
        # A detached detail fully within the current cell must survive.
        draw.rectangle((52, 48, 54, 51), fill=(80, 180, 240, 128))
        return image

    def test_previous_row_shoes_do_not_float_above_head(self):
        cleaned, removed = isolate_cell(self.fixture())
        self.assertGreater(removed, 0)
        self.assertIsNone(cleaned.getchannel('A').crop((0, 0, 64, 5)).getbbox())

    def test_faint_bridge_does_not_attach_shoe_fragment_to_hair(self):
        image = self.fixture()
        draw = ImageDraw.Draw(image)
        draw.line((20, 3, 20, 9), fill=(10, 10, 10, 40))
        draw.line((13, 1, 29, 1), fill=(10, 10, 10, 60))
        cleaned, removed = isolate_cell(image)
        self.assertGreater(removed, 0)
        self.assertEqual(cleaned.getpixel((16, 1))[3], 0)
        self.assertEqual(cleaned.getpixel((14, 1))[3], 0)
        self.assertEqual(cleaned.getpixel((20, 15)), image.getpixel((20, 15)))

    def test_edge_reaching_attack_hand_survives(self):
        before = self.fixture()
        after, _ = isolate_cell(before)
        self.assertEqual(before.crop((40, 20, 64, 27)).tobytes(), after.crop((40, 20, 64, 27)).tobytes())
        self.assertEqual(before.crop((12, 10, 43, 61)).tobytes(), after.crop((12, 10, 43, 61)).tobytes())

    def test_reported_fighter_attack_has_no_pixels_above_hair(self):
        root = Path(__file__).resolve().parents[2]
        atlas = Image.open(root / 'assets/characters/fighter/demo-atlas.png').convert('RGBA')
        # Right-facing attack, second frame: the two old shoe-outline lines.
        above_hair = atlas.getchannel('A').crop((128 + 23, 640 + 33, 128 + 105, 640 + 35))
        self.assertIsNone(above_hair.getbbox())

    def test_internal_detached_detail_and_empty_cell_survive(self):
        before = self.fixture()
        after, _ = isolate_cell(before)
        self.assertEqual(before.getpixel((53, 49)), after.getpixel((53, 49)))
        empty = Image.new('RGBA', (64, 64))
        cleaned, removed = isolate_cell(empty)
        self.assertEqual(empty.tobytes(), cleaned.tobytes())
        self.assertEqual(removed, 0)


if __name__ == '__main__':
    unittest.main()
