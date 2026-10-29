"""Slice generated sources with one shared body scale and ground anchor."""
from pathlib import Path
from PIL import Image
import argparse
from sprite_cells import isolate_cell

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--bodies-only", action="store_true", help="Preserve existing sword textures")
args = parser.parse_args()

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs/art/slayer/demo-source"
sheet = Image.open(SOURCE / "body-sheet.png").convert("RGBA")
assert sheet.size == (1024, 1536), sheet.size
atlas = Image.new("RGBA", (128 * 4, 128 * 6))
removed = 0
for row in range(6):
    for column in range(4):
        cell = sheet.crop((column * 256, row * 256, (column + 1) * 256, (row + 1) * 256))
        cell, debris = isolate_cell(cell)
        removed += debris
        # The same transform for every frame: source feet y=248 -> destination y=112.
        cell = cell.resize((82, 82), Image.Resampling.NEAREST)
        atlas.alpha_composite(cell, (column * 128 + 23, row * 128 + 33))
atlas.save(ROOT / "assets/characters/slayer/demo-atlas.png")
print(f"slayer: removed {removed} neighboring-cell alpha pixels")
if args.bodies_only:
    raise SystemExit(0)

weapons = Image.open(SOURCE / "swords.png").convert("RGBA")
for index, name in enumerate(("steel", "cyan")):
    width = weapons.width // 2
    cell = weapons.crop((index * width, 0, (index + 1) * width, weapons.height))
    # Ignore nearly transparent edge noise when finding equipment bounds.
    bounds = cell.getchannel("A").point(lambda value: 255 if value > 128 else 0).getbbox()
    sword = cell.crop(bounds)
    sword.thumbnail((32, 80), Image.Resampling.NEAREST)
    result = Image.new("RGBA", (48, 96))
    result.alpha_composite(sword, ((48 - sword.width) // 2, 8))
    result.save(ROOT / f"assets/weapons/sword-{name}.png")
