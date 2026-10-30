"""Verify the shipped atlas retains source records and registered equipment grips."""
import json
from collections import deque
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

    @staticmethod
    def hair_width(image):
        pixels = image.load()
        remaining = {(x, y) for y in range(85) for x in range(128)
                     if (lambda r, g, b, a: a > 128 and r > 160 and g > 130 and g > r * .76 and g > b * 1.12 and b > 60)(*pixels[x, y])}
        groups = []
        while remaining:
            seed = remaining.pop();queue = deque([seed]);group = [seed]
            while queue:
                x, y = queue.popleft()
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        point = (x + dx, y + dy)
                        if point in remaining:
                            remaining.remove(point);queue.append(point);group.append(point)
            groups.append(group)
        group = max(groups, key=len)
        return max(x for x, y in group) - min(x for x, y in group) + 1

    def test_thrust_keeps_neutral_model_head_scale_and_standing_proportions(self):
        neutral = self.cell(self.data['clips']['idle_right'], 0)
        canonical_width = self.hair_width(neutral)
        canonical_height = neutral.getbbox()[3] - neutral.getbbox()[1]
        for facing in ('left', 'right'):
            clip = self.data['clips']['dashattack_' + facing]
            for column in range(7):
                image = self.cell(clip, column)
                width = self.hair_width(image)
                self.assertLessEqual(abs(width - canonical_width), 3, 'Head must not shrink during thrust')
                if column < 2:  # Neutral/guard poses; lunges intentionally bend knees.
                    height = image.getbbox()[3] - image.getbbox()[1]
                    self.assertLessEqual(abs(height - canonical_height), 6)
                    self.assertLessEqual(abs(width / height - canonical_width / canonical_height), .05)
        scales = {v['scale'] for v in self.data['source_motion_registration'] if v['action'] == 'dashattack'}
        self.assertEqual(scales, {.26}, 'Use one uniform source scale; do not resize poses to their bounds')

    def test_run_is_separate_from_walk_and_facings_are_independently_drawn(self):
        clips = self.data['clips']
        self.assertNotEqual(clips['run_left']['row'], clips['walk_left']['row'])
        self.assertEqual(len(set(clips['run_left']['cells'])), 8)
        for action in ('run', 'attack1', 'attack2', 'attack3', 'dashattack'):
            left, right = clips[action + '_left'], clips[action + '_right']
            self.assertNotEqual(self.cell(left, 0).tobytes(), ImageOps.mirror(self.cell(right, 0)).tobytes())


if __name__ == '__main__':
    unittest.main()
