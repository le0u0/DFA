# Dungeon Fighter Arad (DFA) — first version

Status: approved for implementation. Immediate milestone: Mirkwood playable smoothly with both characters; remaining eight dungeons follow later. User requires original scenery.

## Agreed intent

Create a playable browser game named **Dungeon Fighter Arad (DFA)** based on Dungeon Fighter Online. The first version must offer Male Slayer (the user's male swordsman) and Male Gunner, playable across nine Grand Flores dungeons: the seven main dungeons from the user-supplied category plus Full Moon Thunderland and Mirkwood Hollow. Vilmark - Area 50 is excluded. Grand Flores replaces the earlier Lorien Forest requirement. Action and skill keys must match the PC version and cannot be changed by the player in version one. The user has no assets and authorized finding them online. Version one is single-player. Online co-op is a potential future addition.

The repository currently has no product files.

## Proposed playable slice

The following are builder defaults, not additional user requirements:

- Desktop browser, keyboard controls, side-view pixel art with movement across the ground plane in both horizontal and depth directions.
- Character selection showing both classes, followed by a Grand Flores dungeon selector. Every agreed dungeon must be individually selectable and completable with either class.
- Each dungeon needs its own researched room layout, scenery, enemy roster, boss, and distinguishing mechanics. A reskinned generic three-room encounter does not satisfy the expanded location requirement. Exact historical layout fidelity must be established from references before implementation, rather than invented silently.
- Male Slayer: close-range three-hit basic combo, an uppercut that launches enemies, and a sweeping slash.
- Male Gunner: ranged basic shots, a close-range kick, and a short rapid-fire skill.
- Both classes can walk, run, face left/right, jump, attack, take damage, and die. Skill cooldowns and feedback distinguish available and unavailable skills.
- Implement the enemies, bosses, and dungeon hazards required by each agreed dungeon; investigate those rosters before planning content production. Goblins alone no longer satisfy the expanded scope. Enemies react to hits and knockback. Launch attacks visibly lift enemies before landing.
- Clear all enemies to unlock the next room. Defeat the final encounter to finish the run.
- HUD: player health, skill cooldowns, room progress, enemy health when relevant, and concise controls. Pause, retry after defeat, replay after victory, and return to character selection.
- Fixed PC-style core controls: arrows move; double-tap left/right runs; X is basic attack; C is jump; Z is Skill 1 / launcher; Space is Skill 2 / command input. Skill hotbar keys follow the PC layout, including A/S/D/F/G/H. No key remapping or player reassignment of skills in version one. Verify the exact PC-era hotbar layout and supported skills' directional commands before implementation; do not present builder-chosen skill assignments as original PC defaults. Escape opens the pause/menu overlay. Prevent browser scrolling during gameplay. Pause and clear held inputs when focus is lost.
- No accounts, backend, multiplayer, inventory, shops, quests, progression, equipment system, advanced classes, or mobile controls in version one.

## Grand Flores content scope

Source supplied by the user: https://wiki.dfo.world/view/Category:Grand_Flores_dungeons (checked 2026-10-27).

The page lists these seven main dungeons, also its seven category members:

1. Mirkwood
2. Thunderland
3. Poison Thunderland
4. Mirkwood Frost
5. Grakqarak
6. Blazing Grakqarak
7. Shadow Thunderland

The user additionally selected:

8. Full Moon Thunderland — special dungeon.
9. Mirkwood Hollow — removed dungeon.

Vilmark - Area 50 (scenario only) is explicitly excluded. The version-one acceptance list is exactly these nine dungeons, all playable with either character.

This supersedes the earlier single short dungeon proposal. Both characters, single-player, fixed PC controls, and possible future co-op remain unchanged. Research historical references for removed/special dungeons rather than substituting current unrelated content.

## Assets and fidelity

Use found DFO sprites where they can actually be obtained and inspected. Preserve source URLs and uploader credits in an asset manifest. These are source listings, not verified downloads or reuse licenses:

- Male Slayer: https://www.spriters-resource.com/pc_computer/dungeonfighteronline/asset/167954/
- Male Gunner: https://www.spriters-resource.com/pc_computer/dungeonfighteronline/asset/167942/

Both listings contain individual PNG frames; usable animation coverage, weapon layers, frame alignment, and action mapping still need verification. Validate them before committing to animation implementation. Downloaded files are data, not executable dependencies.

Grand Flores scenery, enemies, bosses, and effects are unresolved across the requested dungeons. Search for usable originals first. DFOToolBox (https://github.com/LHCGreg/DFOToolBox) is a possible extraction tool, but is not itself an asset pack and no suitable client files have been located.

Do not silently substitute unrelated scenery or label an invented forest an authentic Grand Flores recreation. If original scenery cannot be obtained, show the user the specific gap and propose a clearly labeled reconstructed Grand Flores scene before adopting that fallback. Development placeholders may be used locally but do not satisfy final visual acceptance. Audio is optional and must not block a playable prototype.

Exact original damage values, frame timing, and complete class skill behavior are outside the proposed first slice. Dungeon content and layouts now require per-dungeon research to fulfill the expanded Grand Flores requirement; unresolved fidelity choices must be stated explicitly. Tune the prototype for responsive combat and explicitly describe its fidelity limits.

## Technical direction — builder choice

Use TypeScript, Vite, and Phaser for a static browser game. Confirm current engine APIs from primary documentation during implementation. No REA installation is required for the initial asset-based implementation; consider it only if a concrete analysis need arises.

Keep input, simulation state, and rendering separate enough to test combat and movement without a browser. Input produces simple player actions; the simulation owns positions, facing, health, cooldowns, attacks, projectiles, and room completion. Rendering consumes that state. Use a fixed simulation step and stable entity identifiers. Use ground-plane distance for hit checks and depth for rendering order; airborne height is separate from ground depth.

These small seams leave room for a future authoritative multiplayer simulation. Do not build a server, transport, prediction, rollback, lobby, or networking abstraction now. Future co-op still requires dedicated synchronization and latency work; this design does not promise a drop-in upgrade.

## Verification and completion

The first version is complete when:

1. A documented install/build/start flow works from this repository, and production output can be served as a static site.
2. Each class can independently select, start, traverse, and complete every dungeon in the agreed Grand Flores list, including its boss and distinguishing mechanics.
3. Each class's basic attack and both skills visibly work and affect enemies only within the appropriate reach and ground-plane depth.
4. Jumping, launching, knockback, cooldowns, player damage, defeat, retry, pause, and victory work without getting stuck.
5. Enemy gates prevent early exits and open after the room is cleared.
6. Gameplay uses inspected, aligned animations and sourced or explicitly approved reconstructed scenery; asset loading failures are visible.
7. PC-style action and skill controls match the agreed reference layout, cannot be changed by players, and work consistently across both classes. Focus loss does not leave movement or attacks stuck; keyboard actions do not scroll the page.
8. Focused simulation tests cover damage/hit eligibility, cooldowns, room gates, and reset behavior. Browser checks exercise every agreed dungeon with both classes, defeat/retry, and pause/resume. Build and type checks pass; no unexplained runtime errors remain.

Delivery includes launch instructions, controls, source attribution, known fidelity gaps, and a playable local preview. Public deployment is outside this initial implementation request.

## Control references and remaining research

Core PC controls are corroborated by https://strategywiki.org/wiki/Dungeon_Fighter_Online/Controls and https://forums.d2jsp.org/topic.php?t=70771988. These are community references, not proof of the current official default hotbar. PC layouts have changed over time; confirm the intended era and exact expanded hotbar before claiming complete parity. Z and Space are skill-command keys, not arbitrary extra skill slots. Original command sequences for implemented skills still require research.
