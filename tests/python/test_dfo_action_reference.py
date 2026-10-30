"""Motion import semantics: preserve source ordering, holds and repeated boxes."""
import sys
from pathlib import Path
import struct
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'tools'))
from import_dfo_action_reference import base_motions, parse_animation, tokens


def frame(number, index, delay, boxes=()):
    result = [(3, f'[FRAME{number:03}]'), (3, '[IMAGE EX]'), (0, 0), (0, index),
              (3, '[IMAGE POS]'), (0, -248), (0, -375), (3, '[DELAY]'), (0, delay)]
    for box in boxes:
        result += [(3, '[ATTACK BOX]')] + [(0, value) for value in box]
    return result


class ActionReferenceTests(unittest.TestCase):
    def test_preserves_repeated_pose_long_hold_and_multiple_attack_boxes(self):
        a, b = [1, 2, 3, 4, 5, 6], [6, 5, 4, 3, 2, 1]
        clip = parse_animation([(3, '[FRAME MAX]'), (0, 3)] + frame(0, 23, 100)
                               + frame(1, 24, 100, [a, b]) + frame(2, 24, 10000, [a]))
        self.assertEqual([f['image_index'] for f in clip['frames']], [23, 24, 24])
        self.assertEqual([f['delay_ms'] for f in clip['frames']], [100, 100, 10000])
        self.assertEqual(clip['total_raw_delay_ms'], 10200)
        self.assertEqual(clip['long_hold_frames'], [2])
        self.assertEqual(clip['attack_box_frames'], [1, 2])
        self.assertEqual(clip['frames'][1]['attack_boxes'], [a, b])
        self.assertEqual(clip['frames'][0]['image_pos'], [-248, -375])

    def test_rejects_incomplete_or_misnumbered_clips(self):
        for stream in [[(3, '[FRAME MAX]'), (0, 2)] + frame(0, 0, 50),
                       [(3, '[FRAME MAX]'), (0, 1)] + frame(1, 0, 50),
                       [(3, '[FRAME MAX]'), (0, 1)] + frame(0, 0, 0)]:
            with self.assertRaises(ValueError):
                parse_animation(stream)

    def test_character_links_select_base_dash_and_complete_attack_chain(self):
        stream = [(3, '[waiting motion]'), (6, 'Animation/Stay.ani'),
                  (3, '[move motion]'), (6, 'Animation/Move.ani'),
                  (3, '[dash motion]'), (6, 'Animation/Dash.ani'),
                  (3, '[attack motion]'), (6, 'Animation/Attack1.ani'), (6, 'Animation/Attack2.ani'),
                  (3, '[/attack motion]'), (3, '[growtype attack motion]'), (6, 'Animation/Other.ani')]
        motions = base_motions(stream)
        self.assertEqual(motions['run'], 'Animation/Dash.ani')
        self.assertEqual(motions['attack2'], 'Animation/Attack2.ani')
        self.assertEqual(len(motions), 5)

    def test_token_stream_resolves_string_types_and_float_values(self):
        raw = struct.pack('<Bi', 3, 5) + struct.pack('<Bi', 8, 7) + struct.pack('<Bf', 2, 1.5)
        self.assertEqual(tokens(raw, lambda n: {5: '[tag]', 7: 'text'}[n]),
                         [(3, '[tag]'), (8, 'text'), (2, 1.5)])
        with self.assertRaises(ValueError):
            tokens(raw[:-1], lambda n: '')


if __name__ == '__main__':
    unittest.main()
