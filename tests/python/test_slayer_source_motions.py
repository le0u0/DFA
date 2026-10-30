"""Verify source timeline records and fixed-model asset packaging. Legacy atlas checks do not certify anatomy."""
import json
from pathlib import Path
import unittest
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[2]


class SlayerMotionAssets(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = json.loads((ROOT / 'assets/characters/slayer/animation-proof/animations.json').read_text())
        cls.source = json.loads((ROOT / 'docs/art/roster/dfo-actions/slayer.json').read_text())
        cls.source['clips']['dashattack'] = json.loads((ROOT / 'docs/art/slayer/motion-review/dashattack-source.json').read_text())
        cls.atlas = Image.open(ROOT / 'assets/characters/slayer/animation-proof/body-atlas.png').convert('RGBA')

    def cell(self, clip, column):
        return self.atlas.crop((column * 128, clip['row'] * 128, (column + 1) * 128, (clip['row'] + 1) * 128))

    def test_source_timeline_keeps_repeated_poses_and_original_raw_delays(self):
        for facing in ('left', 'right'):
            for action in ('run', 'attack1', 'attack2', 'attack3', 'dashattack'):
                clip = self.data['clips'][action + '_' + facing]
                reference = self.source['clips'][action]
                indices = [f['image_index'] for f in reference['frames']]
                unique = list(dict.fromkeys(indices))
                self.assertEqual([unique[c] for c in clip['cells']], indices)
                self.assertEqual(clip['durations'], [f['delay_ms'] / 1000 for f in reference['frames']])
                self.assertEqual(clip['source_image_indices'], indices)
                self.assertEqual(clip['impact_frame'], reference['attack_box_frames'][0] if reference['attack_box_frames'] else -1)

    def test_all_new_cells_fit_and_each_equipment_grip_touches_body(self):
        self.assertEqual(self.atlas.size, (1024, 2048))
        for clip in self.data['clips'].values():
            if not clip.get('source'):
                continue
            for column in set(clip['cells']):
                box = self.cell(clip, column).getbbox()
                self.assertIsNotNone(box)
                self.assertTrue(0 < box[0] < box[2] < 128 and 0 < box[1] < box[3] < 128)
            for column, (x, y) in zip(clip['cells'], clip['hands']):
                self.assertGreater(self.cell(clip, column).getpixel((x, y))[3], 128)

    def test_full_combo_entry_keeps_the_same_body_grip_and_sword(self):
        for facing in ('left', 'right'):
            for prior, following in [('attack1', 'attack2'), ('attack2', 'attack3')]:
                a, b = self.data['clips'][prior + '_' + facing], self.data['clips'][following + '_' + facing]
                self.assertEqual(self.cell(a, a['cells'][-1]).tobytes(), self.cell(b, b['cells'][0]).tobytes())
                self.assertEqual(a['hands'][-1], b['hands'][0])
                self.assertEqual(a['sword_angles'][-1], b['sword_angles'][0])

    def test_fixed_model_parts_are_complete_and_bones_match_art_dimensions(self):
        path = ROOT / 'assets/characters/slayer/model'
        model = json.loads((path / 'model.json').read_text())
        self.assertEqual(model, json.loads((ROOT / 'docs/art/slayer/model/proportions.json').read_text()))
        self.assertEqual(model['head'][1] + model['chin_to_hips'] + model['hips_to_soles'], model['standing_height'])
        for name in ('head_left', 'head_right', 'head_back'):
            self.assertEqual(model['parts'][name]['size'], model['head'])
        self.assertEqual(model['parts']['torso_front']['size'], model['parts']['torso_back']['size'])
        self.assertEqual(model['parts']['boot_left']['size'], model['parts']['boot_right']['size'])
        self.assertGreaterEqual(model['thigh_width'] / model['thigh_length'], .8)
        self.assertGreaterEqual(model['shin_width'] / model['shin_length'], .8)
        pairs = [('thigh', model['thigh_length']), ('shin', model['shin_length']),
                 ('upper_arm', model['normal_arm'][0]), ('forearm', model['normal_arm'][1]),
                 ('cursed_upper', model['cursed_arm'][0]), ('cursed_forearm', model['cursed_arm'][1])]
        for name, length in pairs:
            self.assertEqual(model['parts'][name]['size'][1], length + 4)
        with Image.open(path / 'parts.png') as parts:
            for name, entry in model['parts'].items():
                x, y, w, h = entry['rect']
                self.assertTrue(0 <= x < x + w <= parts.width and 0 <= y < y + h <= parts.height, name)
                self.assertIsNotNone(parts.crop((x, y, x + w, y + h)).getbbox(), name)

    def test_run_is_separate_from_walk_and_facings_are_independently_drawn(self):
        clips = self.data['clips']
        self.assertNotEqual(clips['run_left']['row'], clips['walk_left']['row'])
        self.assertEqual(len(set(clips['run_left']['cells'])), 8)
        for action in ('run', 'attack1', 'attack2', 'attack3', 'dashattack'):
            left, right = clips[action + '_left'], clips[action + '_right']
            self.assertNotEqual(self.cell(left, 0).tobytes(), ImageOps.mirror(self.cell(right, 0)).tobytes())


if __name__ == '__main__':
    unittest.main()
