# Slayer animation source and gameplay status

Test through **Start → Slayer → Enter dungeon**, the same flow as every other character. The separate Slayer art demo and animation lab have been removed, along with the main menu's Offline subtitle.

Slayer's latest recreated chibi idle/walk/attack sheet is now connected to gameplay. It has six frames per action/facing, independently authored facings and separate sword equipment. Normal movement, damage, hit windows, collision and equipment stats remain controlled by the existing game code.

## Why these actions do not yet match DFO

The supplied NPKs yielded sprite images and numeric frame indices. They did not establish which frames form each run, combo stage, aerial/running attack or skill, nor the original delays and attack events. The earlier prototype used generic generated poses; running reused the walk strip at a higher rate. That is not a completed recreation of the original actions.

Connecting the latest Slayer sheet through Start does not resolve that missing mapping. Its attacks remain provisional, the right windup holds guard, and running still reuses walk art. The other four classes retain their older four-frame source sheets. These are explicit remaining tasks, not verified source-faithful animations.

The next input is the original basic `.ani` action definitions and `.chr` links from `Script.pvf`, followed by a frame-by-frame retargeting pass into our approved chibi designs. Preserve original action variants, pose order and durations; keep body/equipment separate. If source timing differs from current combat tuning, assess the impact boundary explicitly rather than silently changing gameplay to fit generated art.

## Extract the missing reference on your Mac

With `~/Documents/DFO.zip` still present, run in this repository:

```sh
python3 tools/extract-dfo-action-reference.py
```

Upload **Documents/DFO-action-reference.zip** in our chat. This standard-library-only tool reads the PVF index and selected data directly inside the ZIP; it does not unpack the 44 GB game or write the entire 667 MB PVF. The reference output is kept below the per-file upload limit. If this client uses an unsupported PVF variant, it creates `DFO-action-diagnostic.zip` instead; upload that diagnostic.

The container reader is checked against an independently assembled encrypted PVF fixture. It has not yet been tested against this user's actual Script.pvf, which is not present in the cloud workspace.

## Test gameplay on your Mac

Use the [Docker/browser setup](../../../../docker/README.md), or open `project.godot` in Godot and press F5.

1. Choose **Start**, select **Slayer** and choose **Training · Immortal goblin** for repeatable checks.
2. Use arrows to walk and double-tap left/right to run; compare the current fallback visually, without treating it as the original run.
3. Use **X** for combos, **Z** for class skill, **C** for jump, **Space** for dodge and **V** to compare separate swords.
4. Use **Esc** to pause or return through the pause menu.

## Preserved art sources

Unmodified generated source sheets, prompts and provenance remain here. Runtime atlas, authored timing/grips and registration are in `assets/characters/slayer/animation-proof/`. One source scale is used for all cells. A generated right overhead pose with swapped cursed-arm anatomy was deliberately rejected; the runtime guard hold remains a known visual limitation.

Historical paired-facing inspection captures: [idle](idle-preview.gif), [walk](walk-preview.gif), [attack](attack-preview.gif). They are source-sheet review clips, not evidence of matched original gameplay animation.

Rebuild source assets with Python/Pillow:

```sh
python3 tools/normalize-slayer-animation-proof.py
```
