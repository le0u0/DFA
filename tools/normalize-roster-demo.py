"""Normalize generated roster strips with one scale and baseline per sheet."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs/art/roster/demo-source"
for name in ("gunner", "fighter", "mage", "priest"):
    sheet = Image.open(SOURCE / f"{name}-sheet.png").convert("RGBA")
    assert sheet.width % 4 == 0 and sheet.height % 6 == 0, sheet.size
    width, height = sheet.width // 4, sheet.height // 6
    atlas = Image.new("RGBA", (512, 768))
    for row in range(6):
        for column in range(4):
            cell = sheet.crop((column * width, row * height, (column + 1) * width, (row + 1) * height))
            # Fixed transform across every frame, matching the Slayer trial scale.
            cell = cell.resize((82, 82), Image.Resampling.NEAREST)
            atlas.alpha_composite(cell, (column * 128 + 23, row * 128 + 33))
    destination = ROOT / "assets/characters" / name
    destination.mkdir(parents=True, exist_ok=True)
    atlas.save(destination / "demo-atlas.png")

equipment = Image.open(SOURCE / "equipment.png").convert("RGBA")
width, height = equipment.width // 4, equipment.height // 2
for column, name in enumerate(("pistol", "gauntlet", "staff", "cross")):
    for row in range(2):
        cell = equipment.crop((column * width, row * height, (column + 1) * width, (row + 1) * height))
        bounds = cell.getchannel("A").point(lambda value: 255 if value > 128 else 0).getbbox()
        item = cell.crop(bounds)
        canvas_width = 64 if name == "cross" else 48
        item.thumbnail((canvas_width - 8, 80), Image.Resampling.NEAREST)
        texture = Image.new("RGBA", (canvas_width, 96))
        texture.alpha_composite(item, ((canvas_width - item.width) // 2, 8))
        texture.save(ROOT / f"assets/weapons/{name}-{row}.png")
