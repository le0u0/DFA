"""Import the five base-job motions from a locally supplied DFO reference ZIP.

Only reads binary data; no game script or executable is run. The .chr motion
links choose the base jobs, excluding opposite-sex and subclass animations.
"""
import argparse
from collections import defaultdict
import hashlib
import json
import mmap
from pathlib import Path, PurePosixPath
import re
import struct
import tempfile
import zipfile
import zlib

JOBS = {'slayer': 'swordman', 'fighter': 'fighter', 'gunner': 'gunner', 'mage': 'mage', 'priest': 'priest'}
STRING_TYPES = (3, 5, 6, 7, 8, 10)


class Pools:
    def __init__(self, archive):
        self.buffers = {}
        self.files = []
        for wide, name in ((0, 'utf8'), (1, 'utf16')):
            path = f'pools/{name}.zlib'
            if path not in archive.namelist():
                self.buffers[wide] = b''
                continue
            target = tempfile.TemporaryFile()
            self.files.append(target)
            decoder = zlib.decompressobj()
            total = 0
            with archive.open(path) as source:
                while block := source.read(65536):
                    while block:
                        raw = decoder.decompress(block, 1024 * 1024)
                        total += len(raw)
                        if total > 0x7FFFFFFF:
                            raise ValueError('Reference string pool exceeds signed 32-bit size')
                        target.write(raw)
                        block = decoder.unconsumed_tail
            if not decoder.eof:
                raise ValueError('Truncated reference string pool')
            target.flush()
            self.buffers[wide] = mmap.mmap(target.fileno(), 0, access=mmap.ACCESS_READ) if total else b''

    def close(self):
        for pool in self.buffers.values():
            if isinstance(pool, mmap.mmap):
                pool.close()
        for target in self.files:
            target.close()

    def resolve(self, value):
        if value < 0:
            return ''
        wide = value & 1
        pool = self.buffers[wide]
        start = (value >> 1) * (2 if wide else 1)
        if start >= len(pool):
            raise ValueError(f'Action token string {value} exceeds pool {wide}')
        if wide:
            end = start
            while end + 1 < len(pool) and pool[end:end + 2] != b'\0\0':
                end += 2
            return pool[start:end].decode('utf-16-le')
        end = pool.find(b'\0', start)
        return pool[start:len(pool) if end < 0 else end].decode('utf-8')


def tokens(raw, resolve):
    if len(raw) % 5:
        raise ValueError('Action payload is not a complete five-byte token stream')
    result = []
    for kind, value in struct.iter_unpack('<Bi', raw):
        if kind in STRING_TYPES:
            value = resolve(value)
        elif kind == 2:
            value = struct.unpack('<f', struct.pack('<i', value))[0]
        elif kind != 0:
            raise ValueError(f'Unsupported action token type {kind}')
        result.append((kind, value))
    return result


def sections(stream):
    result = []
    for kind, value in stream:
        if kind == 3:
            result.append(dict(tag=value, values=[]))
        elif result:
            result[-1]['values'].append(value)
        else:
            raise ValueError('Action value has no section')
    return result


def parse_animation(stream):
    header, frames = [], []
    current = None
    for item in sections(stream):
        match = re.fullmatch(r'\[FRAME(\d+)\]', item['tag'])
        if match:
            number = int(match.group(1))
            if number != len(frames):
                raise ValueError('Non-consecutive ANI frame numbering')
            current = dict(frame=number, sections=[])
            frames.append(current)
        elif current is None:
            header.append(item)
        else:
            current['sections'].append(item)
    counts = [item['values'] for item in header if item['tag'] == '[FRAME MAX]']
    if counts != [[len(frames)]] or not frames:
        raise ValueError('ANI frame count differs from FRAME MAX')
    for frame in frames:
        values = defaultdict(list)
        for item in frame['sections']:
            values[item['tag']].append(item['values'])
        for required, width in (('[IMAGE EX]', 2), ('[IMAGE POS]', 2), ('[DELAY]', 1)):
            if len(values[required]) != 1 or len(values[required][0]) != width:
                raise ValueError(f'Unsupported frame layout for {required}')
        image = values['[IMAGE EX]'][0]
        delay = values['[DELAY]'][0][0]
        if not all(isinstance(v, int) and v >= 0 for v in image) or not isinstance(delay, int) or delay <= 0:
            raise ValueError('Invalid image index or delay')
        frame.update(image_slot=image[0], image_index=image[1], image_pos=values['[IMAGE POS]'][0],
                     delay_ms=delay, attack_boxes=values['[ATTACK BOX]'], damage_boxes=values['[DAMAGE BOX]'])
    return dict(header=header, frames=frames, total_raw_delay_ms=sum(f['delay_ms'] for f in frames),
                attack_box_frames=[f['frame'] for f in frames if f['attack_boxes']],
                long_hold_frames=[f['frame'] for f in frames if f['delay_ms'] >= 10000])


def base_motions(stream):
    fields = {}
    for item in sections(stream):
        fields.setdefault(item['tag'], item['values'])
    result = {}
    for action, tag in [('idle', '[waiting motion]'), ('walk', '[move motion]'), ('run', '[dash motion]')]:
        values = fields.get(tag, [])
        if len(values) != 1 or not isinstance(values[0], str):
            raise ValueError(f'Missing base character motion {tag}')
        result[action] = values[0]
    attacks = fields.get('[attack motion]', [])
    if not attacks or not all(isinstance(v, str) for v in attacks):
        raise ValueError('Missing base character attack chain')
    result.update({f'attack{i}': path for i, path in enumerate(attacks, 1)})
    return result


def import_reference(archive_path, output, appearance=None):
    output.mkdir(parents=True, exist_ok=True)
    with archive_path.open('rb') as source:
        archive_hash = hashlib.file_digest(source, 'sha256').hexdigest()
    manifest = dict(version=1, archive_sha256=archive_hash,
                    scope='Five base jobs, chosen through their own .chr motion links', characters={})
    with zipfile.ZipFile(archive_path) as archive:
        source_index = json.loads(archive.read('reference-index.json'))
        manifest['lookup_warnings'] = source_index.get('lookup_warnings')
        pools = Pools(archive)
        try:
            for label, job in JOBS.items():
                source = f'character/{job}/{job}.chr'
                raw = archive.read(source)
                data = dict(character=label, source_character=source, source_sha256=hashlib.sha256(raw).hexdigest(), clips={})
                for action, relative in base_motions(tokens(raw, pools.resolve)).items():
                    path = str(PurePosixPath(source).parent / relative.replace('\\', '/')).lower()
                    if '..' in PurePosixPath(path).parts:
                        raise ValueError('Motion path escapes character folder')
                    raw_ani = archive.read(path)
                    clip = parse_animation(tokens(raw_ani, pools.resolve))
                    clip.update(source=path, source_sha256=hashlib.sha256(raw_ani).hexdigest())
                    data['clips'][action] = clip
                (output / f'{label}.json').write_text(json.dumps(data, indent=2) + '\n')
                manifest['characters'][label] = {action: dict(frames=len(clip['frames']), raw_ms=clip['total_raw_delay_ms'],
                                                            long_hold_frames=clip['long_hold_frames']) for action, clip in data['clips'].items()}
                if appearance:
                    render_reference(data, appearance / label / 'composed', output)
        finally:
            pools.close()
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f"Imported {sum(len(v) for v in manifest['characters'].values())} core clips for five characters into {output}")
    return manifest


def render_reference(data, composed, output):
    from PIL import Image, ImageDraw
    clips = data['clips']
    columns = max(len(clip['frames']) for clip in clips.values())
    bounds = []
    for clip in clips.values():
        for frame in clip['frames']:
            with Image.open(composed / f"{frame['image_index']:03}.png") as image:
                box = image.getbbox()
            if box:
                x, y = frame['image_pos']
                bounds.append((box[0] + x, box[1] + y, box[2] + x, box[3] + y))
    if not bounds:
        raise ValueError('Reference contains no visible poses')
    left, top = min(b[0] for b in bounds), min(b[1] for b in bounds)
    right, bottom = max(b[2] for b in bounds), max(b[3] for b in bounds)
    width, height = max(150, right - left + 16), max(180, bottom - top + 48)
    origin = ((width - (right - left)) // 2 - left, 24 - top)
    sheet = Image.new('RGB', (columns * width, len(clips) * height), '#263b35')
    for row, (action, clip) in enumerate(clips.items()):
        sequence = []
        for column, frame in enumerate(clip['frames']):
            path = composed / f"{frame['image_index']:03}.png"
            if frame['image_slot'] != 0 or not path.exists():
                raise ValueError(f"No verified body pose for {data['character']} {action} frame {frame['frame']}")
            cell = Image.new('RGBA', (width, height), '#263b35')
            image = Image.open(path).convert('RGBA')
            # NPK compositions retain the source canvas; ANI positions register
            # that canvas against the actor origin, without per-pose recentering.
            cell.alpha_composite(image, (origin[0] + frame['image_pos'][0], origin[1] + frame['image_pos'][1]))
            text = ImageDraw.Draw(cell)
            text.line((origin[0]-4, origin[1], origin[0]+4, origin[1]), fill='#6fa287')
            text.text((4, 3), f"{action} / {frame['frame']}", fill='white')
            text.text((4, height - 16), f"IMG {frame['image_index']} / {frame['delay_ms']}ms", fill='white')
            sheet.paste(cell.convert('RGB'), (column * width, row * height))
            sequence.append(cell.convert('RGB'))
        if action in ('run', 'attack1'):
            sequence[0].save(output / f"{data['character']}-{action}.gif", save_all=True, append_images=sequence[1:],
                             duration=[f['delay_ms'] for f in clip['frames']], loop=0, disposal=2)
    sheet.save(output / f"{data['character']}-poses.png")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--appearance', type=Path, help='Optional existing composed appearance PNG root (requires Pillow)')
    args = parser.parse_args()
    import_reference(args.archive, args.output, args.appearance)
