"""Verify the shipped atlas retains source records and registered equipment grips."""
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

    def test_run_is_separate_from_walk_and_facings_are_independently_drawn(self):
        clips = self.data['clips']
        self.assertNotEqual(clips['run_left']['row'], clips['walk_left']['row'])
        self.assertEqual(len(set(clips['run_left']['cells'])), 8)
        for action in ('run', 'attack1', 'attack2', 'attack3', 'dashattack'):
            left, right = clips[action + '_left'], clips[action + '_right']
            self.assertNotEqual(self.cell(left, 0).tobytes(), ImageOps.mirror(self.cell(right, 0)).tobytes())


if __name__ == '__main__':
    unittest.main()
