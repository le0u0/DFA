# Original DFO basic motion references

The two user-supplied `DFO-action-reference.zip.part01` / `.part02` files were joined
and the ZIP CRC check passed for every member. The reference contains 5,704 selected
files and an index of 67,691 character animation/configuration entries. Its extraction
reported three missing string references and **zero** out-of-range references.

The importer follows each base job's own `.chr` links, selecting the intended male
Slayer/Gunner/Priest and female Fighter/Mage. It excludes `at` variants and subclass
motion overrides. **31 core clips / 212 source frame records** are decoded below.
The original names are `Stay` (idle), `Move` (walk), and `Dash` (run).

| Character | Idle frames | Walk frames | Run frames | Frames per basic attack stage |
| --- | ---: | ---: | ---: | --- |
| Slayer | 6 | 8 | 8 | 10, 11, 9 |
| Fighter | 5 | 8 | 8 | 2, 4, 8, 7 |
| Gunner | 15 | 8 | 8 | 3, 7 |
| Mage | 4 | 10 | 4 | 5, 5, 8 |
| Priest | 4 | 8 | 6 | 3, 5, 7, 8 |

Each character JSON retains source member SHA-256 hashes, image paths, ordered IMG
indices (including repeated poses), canvas positions, raw millisecond delays, damage
and attack boxes, and every frame section including flags. `manifest.json` identifies
the joined source archive by SHA-256. No client executable, keys or whole string pool
are committed.

The PNG pose sheets and `*-run.gif` / `*-attack1.gif` files show the existing decoded
appearance compositions, registered using the ANI canvas positions. They are **source
references, not the chibi artwork used by Start**. Appearance stacking remains the
previous provisional composition; weapon layers and separate left-facing artwork
are not established by these previews. Run GIFs loop for inspection; the importer
does not infer source engine looping rules from that presentation.

Gunner attack 1 and attack 2 end with 10,000 ms holds. Those delays are preserved
exactly and flagged as `long_hold_frames`. The action files alone do not establish
the engine's transitions, firing cadence, attack-speed scaling, cancel windows, or
input handling. Do not turn a hold into a ten-second gameplay lock or silently shorten
it. `attack_box_frames` locates source attack boxes, not a verified damage-event schedule.

## Remaining gameplay work

Start still uses the existing generated chibi pose strips. Its run reuses walk art;
its attacks are provisional. These references supply the actual poses and order for
redrawing the five approved designs, keeping equipment separate and checking the
combat impact boundary. Importing data does not make the existing art source-faithful.
No more game uploads are needed for these basic motions. Running attacks, aerial attacks
and skills are outside this core import and must be selected and checked separately.

## Reproduce

With the joined reference archive available locally:

```sh
python3 tools/import_dfo_action_reference.py \
  --archive /path/to/DFO-action-reference.zip \
  --output docs/art/roster/dfo-actions
```

To regenerate the pose sheets and GIFs, also pass `--appearance` pointing to the
previously decoded five-character appearance directory (`slayer/composed/000.png`,
etc.). Rendering requires Pillow. Parsing uses only the Python standard library and
temporary disk storage for the large reference string pool. Game scripts are data;
they are never executed.
