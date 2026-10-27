# Asset sources

Original game artwork belongs to Neople / Nexon and its respective rights holders. Public availability does not establish a redistribution license. No claim that these images are original DFA artwork.

## Original sprite layers

- Resource source: https://github.com/2DScrollGames/DFQ-Original
- Source revision: d4b9088d9e6efeede3e504d3b6e64e3a459aa012
- Archive: https://codeload.github.com/2DScrollGames/DFQ-Original/zip/refs/heads/master
- Images: `asset/image/actor/duelist/{swordman,goblin,tau}/`.
- Alignment metadata: matching `config/asset/sprite/` files.
- Preparation combines existing image layers using their supplied origins, trims transparency, and packs selected frames into an atlas. It does not redraw the artwork.
- The inspected Lorien scene layers were replaced with the single original forest scene described below; those unused layers are not included.
- Tau resources are labeled `army` in the source; exact Tau Beast boss appearance is still under verification.

## Located but not downloaded

The Spriters Resource: Male Slayer (167954), Male Gunner (167942), uploaded by Firejoker54. Direct ZIP requests returned 403. No files from those listings are included yet.

## Authored elements

DFA menus, HUD, geometry-only hit indicators, projectile indicators, combat tuning, and room composition are authored for this implementation. They are not extracted DFO behavior or scenery.

## Male Gunner (included)

- Source: Supaman Presents: DFO Sprite sheets, posted by bilal riley / supaman2525.
- Thread: https://www.chronocrash.com/forum/threads/supaman-presents-dfo-sprite-sheets.4245/
- Archive: https://www.mediafire.com/file/5mfrm8w5spz9i11/DFO_Spritesheets.rar/file
- Sheet: `DFO Spritesheets/ezgif-5-fcba9dbc4693.png`, 1075 × 9030, 5 columns of 215px cells.
- Original red-coat Male Gunner avatar. This is not a claim that its costume is the default base-class costume.
- Selected frames are cropped without recoloring, with a shared cell origin. The atlas includes idle, walk, shoot, launcher/kick, hit, airborne and downed poses. Skill animation timings are authored.
- Alternate dawnbreak artwork was inspected and rejected; it is not included.

## Forest scene (included)

- Source: https://github.com/QdWan/FND/blob/master/src/res/scene/bg/3.jpg
- Direct original image: https://raw.githubusercontent.com/QdWan/FND/master/src/res/scene/bg/3.jpg
- The JPEG is included unmodified as `forest-scene.jpg`. It provides the complete original forest scene; no generated art or reconstructed layer composition is used.
- Exact correspondence to a particular historical Mirkwood room is still unverified; this is a remaining fidelity limit, not a verified original map export.
