import "./style.css";
import {
  CHARACTERS,
  HEIGHT,
  ROOMS,
  WIDTH,
  type CharacterId,
} from "./game/content";
import { createWorld, stepWorld, type World } from "./game/simulation";
import { KeyboardInput } from "./game/input";
import { loadAssets } from "./game/assets";
import { Renderer } from "./game/renderer";

const app = document.querySelector<HTMLDivElement>("#app")!;
app.innerHTML = `
<header class="site-header"><a class="wordmark" href="./" aria-label="Dungeon Fighter Arad home"><span class="mark">DFA</span><span>Dungeon Fighter <b>Arad</b></span></a><span class="build-label">MIRKWOOD · SINGLE PLAYER</span><button class="quiet" id="help-button">Controls <kbd>?</kbd></button></header>
<main><div class="stage-heading"><div><span class="region">GRAND FLORES</span><h1>Mirkwood</h1></div><p>Beyond the treeline, your adventure begins.</p></div>
<section class="game-frame" aria-label="Dungeon Fighter Arad game" data-phase="selection"><canvas id="game" width="${WIDTH}" height="${HEIGHT}" aria-label="Mirkwood combat arena"></canvas>
<div class="hud" hidden><div class="player-info"><span id="player-name"></span><span id="hp-text"></span><div class="health-track"><div id="hp-fill"></div></div></div><div class="room-info"><span id="room-name"></span><div id="room-map"></div></div><button class="hud-pause" id="pause-button" aria-label="Pause game">Ⅱ</button></div>
<div class="bottom-hud" hidden><div class="action-keys"><span><kbd>X</kbd> Attack</span><span><kbd>C</kbd> Jump</span></div><div id="skill-bar"></div><span class="command-key"><kbd>Space</kbd> Unassigned</span></div>
<div id="overlay" class="overlay"></div>
<div id="room-hint" class="room-hint" hidden></div>
</section>
<div class="below-stage"><p><kbd>↑</kbd><kbd>←</kbd><kbd>↓</kbd><kbd>→</kbd> Move <span>·</span> Double-tap ← / → to run <span>·</span> <kbd>Esc</kbd> Pause</p><button class="quiet" id="fullscreen-button">Fullscreen ↗</button></div>
<p class="fidelity-note">Fan-made browser adaptation. Original sourced artwork; authored combat tuning and room composition. Mirkwood is the first playable milestone.</p>
</main><footer><span>Dungeon Fighter Arad</span><span>Two fighters. One way forward.</span></footer>`;
const canvas = document.querySelector<HTMLCanvasElement>("#game")!;
const frame = document.querySelector<HTMLElement>(".game-frame")!;
const overlay = document.querySelector<HTMLDivElement>("#overlay")!;
const hud = document.querySelector<HTMLElement>(".hud")!;
const bottomHud = document.querySelector<HTMLElement>(".bottom-hud")!;
const hint = document.querySelector<HTMLElement>("#room-hint")!;
const input = new KeyboardInput();
let selected: CharacterId = "slayer",
  world: World | undefined,
  renderer: Renderer | undefined,
  loadError = "",
  loading = true;
let accumulator = 0,
  last = 0,
  hudClock = 0;
const reducedMotion = matchMedia("(prefers-reduced-motion: reduce)");
function button(id: string, fn: () => void) {
  document.getElementById(id)?.addEventListener("click", fn);
}
function setPhase(phase: string) {
  frame.dataset.phase = phase;
}
function selection() {
  world = undefined;
  input.clear();
  setPhase("selection");
  hud.hidden = true;
  bottomHud.hidden = true;
  hint.hidden = true;
  overlay.hidden = false;
  overlay.className = "overlay selection";
  overlay.innerHTML = `<div class="selection-heading"><p class="chapter">Your journey into Grand Flores</p><h2>Choose your fighter</h2><p>Different weapons. The same fighting spirit.</p></div><div class="fighters">${(["slayer", "gunner"] as const).map((id) => `<button class="fighter ${id === selected ? "selected" : ""}" aria-label="Select ${CHARACTERS[id].name}" aria-pressed="${id === selected}" data-character="${id}"><div class="fighter-art"><canvas width="220" height="235" data-portrait="${id}" aria-hidden="true"></canvas></div><div class="fighter-copy"><span class="fighter-number">${id === "slayer" ? "01" : "02"}</span><h3>${CHARACTERS[id].name}</h3><p>${CHARACTERS[id].weapon} · ${id === "slayer" ? "Close combat" : "Ranged combat"}</p></div><span class="selection-check" aria-hidden="true">${id === selected ? "◆" : "◇"}</span></button>`).join("")}</div><div class="selection-bottom"><p id="class-description">${CHARACTERS[selected].description}</p><button id="start-button" class="primary" ${!renderer ? "disabled" : ""}>Enter Mirkwood <span>→</span></button></div><p class="asset-status ${loadError ? "error" : ""}" role="status">${loading ? "Loading original artwork…" : loadError || "Arrows to move · X to attack · C to jump"}</p>${loadError ? '<button class="quiet" id="retry-assets">Retry loading assets</button>' : ""}`;
  overlay
    .querySelectorAll<HTMLButtonElement>("[data-character]")
    .forEach((el) =>
      el.addEventListener("click", () => {
        selected = el.dataset.character as CharacterId;
        selection();
        overlay
          .querySelector<HTMLButtonElement>(`[data-character="${selected}"]`)
          ?.focus();
      }),
    );
  button("start-button", start);
  button("retry-assets", () => void prepareAssets());
  if (renderer)
    overlay
      .querySelectorAll<HTMLCanvasElement>("[data-portrait]")
      .forEach((el) =>
        renderer!.portrait(el.dataset.portrait as CharacterId, el),
      );
}
async function prepareAssets() {
  loading = true;
  loadError = "";
  selection();
  try {
    renderer = new Renderer(canvas, await loadAssets());
  } catch (error) {
    loadError =
      error instanceof Error
        ? error.message
        : "Original artwork could not be loaded.";
  }
  loading = false;
  selection();
}
function start() {
  if (!renderer) return;
  world = createWorld(selected);
  input.clear();
  accumulator = 0;
  overlay.hidden = true;
  hud.hidden = false;
  bottomHud.hidden = false;
  setPhase("playing");
  canvas.tabIndex = 0;
  canvas.focus();
  updateHud();
}
function updateHud() {
  if (!world) return;
  const w = world,
    p = w.player;
  document.querySelector("#player-name")!.textContent =
    CHARACTERS[p.character].name;
  document.querySelector("#hp-text")!.textContent =
    `${Math.ceil(p.hp)} / ${p.maxHp}`;
  (document.querySelector("#hp-fill") as HTMLElement).style.width =
    `${(p.hp / p.maxHp) * 100}%`;
  document.querySelector("#room-name")!.textContent =
    `${ROOMS[w.room].cell} · ${ROOMS[w.room].name}`;
  document.querySelector("#room-map")!.innerHTML = ROOMS.map(
    (r, i) =>
      `<span class="map-room ${i === w.room ? "current" : i < w.room ? "cleared" : ""} ${i === 4 ? "boss" : ""}" title="${r.cell}: ${r.name}">${i === 4 ? "◆" : ""}</span>`,
  ).join("");
  document.querySelector("#skill-bar")!.innerHTML = CHARACTERS[
    p.character
  ].skills
    .map((s, i) => {
      const key = (["skill1", "skillA", "skillS"] as const)[i],
        cooldown = p.cooldowns[key];
      return `<div class="skill ${cooldown > 0 ? "cooling" : ""}" title="${s.name}"><kbd>${s.key}</kbd><span class="skill-name">${s.name}</span>${cooldown > 0 ? `<span class="cooldown">${cooldown.toFixed(1)}</span>` : ""}</div>`;
    })
    .join("");
  hint.hidden = !w.roomCleared || w.phase !== "playing";
  hint.textContent =
    ROOMS[w.room].exit === "up"
      ? "Room clear · Take the north exit ↗"
      : "Room clear · Continue right →";
}
function pause(showControls = false) {
  if (!world || world.phase !== "playing") return;
  world.phase = "paused";
  input.clear();
  setPhase("paused");
  showPause(showControls);
}
function showPause(showControls = false) {
  overlay.hidden = false;
  overlay.className = "overlay modal-overlay";
  overlay.innerHTML = `<div class="modal"><p class="chapter">DUNGEON FIGHTER ARAD</p><h2>${showControls ? "PC controls" : "Paused"}</h2>${showControls ? controlsMarkup() : "<p>The forest can wait.</p>"}<div class="modal-actions"><button class="primary" id="continue-button">Continue</button><button class="secondary" id="retry-button">Restart Mirkwood</button><button class="quiet" id="choose-button">Choose fighter</button></div></div>`;
  button("continue-button", resume);
  button("retry-button", start);
  button("choose-button", selection);
  document.querySelector<HTMLButtonElement>("#continue-button")?.focus();
}
function resume() {
  if (!world || world.phase !== "paused") return;
  input.clear();
  world.phase = "playing";
  setPhase("playing");
  overlay.hidden = true;
  accumulator = 0;
  canvas.focus();
}
function terminal() {
  if (!world) return;
  input.clear();
  setPhase(world.phase);
  overlay.hidden = false;
  overlay.className = "overlay modal-overlay";
  const win = world.phase === "victory";
  overlay.innerHTML = `<div class="modal result"><p class="chapter">${win ? "GRAND FLORES · MIRKWOOD" : "THE FOREST CLAIMED ANOTHER"}</p><h2>${win ? "Mirkwood cleared" : "Defeated"}</h2><p>${win ? "Tau Beast has fallen. The path through the forest is yours." : "Catch your breath. Your next attempt starts here."}</p>${win ? `<div class="run-stats"><span><b>${Math.floor(world.elapsed / 60)}:${String(Math.floor(world.elapsed % 60)).padStart(2, "0")}</b>Clear time</span><span><b>${world.kills}</b>Enemies defeated</span><span><b>${Math.ceil(world.player.hp)}</b>Health remaining</span></div>` : ""}<div class="modal-actions"><button class="primary" id="replay-button">${win ? "Play again" : "Retry Mirkwood"}</button><button class="secondary" id="choose-button">Choose fighter</button></div></div>`;
  button("replay-button", start);
  button("choose-button", selection);
  document.querySelector<HTMLButtonElement>("#replay-button")?.focus();
}
function controlsMarkup() {
  return `<dl class="controls-list"><dt>Move / Run</dt><dd>Arrows / double-tap ← or →</dd><dt>Basic attack</dt><dd><kbd>X</kbd></dd><dt>Jump</dt><dd><kbd>C</kbd></dd><dt>Skill 1 / launcher</dt><dd><kbd>Z</kbd></dd><dt>Skill hotkeys</dt><dd><kbd>A</kbd> <kbd>S</kbd> · remaining slots unused</dd><dt>Skill 2 command key</dt><dd><kbd>Space</kbd> · no skill assigned yet</dd><dt>Pause</dt><dd><kbd>Esc</kbd></dd></dl><p class="control-note">Action keys follow classic PC defaults. This build has fixed skill assignments and no key remapping.</p>`;
}
button("help-button", () => {
  if (world) {
    if (world.phase === "playing") pause(true);
    else if (world.phase === "paused") showPause(true);
  } else {
    const dialog = document.createElement("dialog");
    dialog.className = "controls-dialog";
    dialog.innerHTML = `<h2>PC controls</h2>${controlsMarkup()}<button class="primary">Close</button>`;
    document.body.append(dialog);
    dialog.querySelector("button")!.onclick = () => dialog.close();
    dialog.addEventListener("close", () => dialog.remove());
    dialog.showModal();
  }
});
button("pause-button", () => pause());
button("fullscreen-button", () => {
  if (document.fullscreenElement) void document.exitFullscreen();
  else
    void frame.requestFullscreen().catch(() => {
      document.querySelector("#fullscreen-button")!.textContent =
        "Fullscreen unavailable";
    });
});
const gameKeys = new Set([
  "ArrowLeft",
  "ArrowRight",
  "ArrowUp",
  "ArrowDown",
  "KeyX",
  "KeyC",
  "KeyZ",
  "KeyA",
  "KeyS",
  "Space",
  "Escape",
]);
window.addEventListener("keydown", (e) => {
  if (!world || !["playing", "paused"].includes(world.phase)) return;
  if (e.code === "Escape" && !e.repeat) {
    e.preventDefault();
    world.phase === "playing" ? pause() : resume();
    return;
  }
  if (world.phase !== "playing") return;
  if (gameKeys.has(e.code)) {
    e.preventDefault();
    input.press(e.code, performance.now());
  }
});
window.addEventListener("keyup", (e) => input.release(e.code));
window.addEventListener("blur", () => pause());
document.addEventListener("visibilitychange", () => {
  if (document.hidden) pause();
});
function loop(now: number) {
  const delta = last ? Math.min(0.066, (now - last) / 1000) : 0;
  last = now;
  if (world && renderer) {
    if (world.phase === "playing") {
      accumulator += delta;
      while (accumulator >= 1 / 60) {
        stepWorld(world, input.sample(), 1 / 60);
        accumulator -= 1 / 60;
        if (world.phase !== "playing") {
          terminal();
          break;
        }
      }
    } else accumulator = 0;
    renderer.draw(world, now / 1000, reducedMotion.matches);
    hudClock += delta;
    if (hudClock > 0.08) {
      updateHud();
      hudClock = 0;
    }
  }
  requestAnimationFrame(loop);
}
// Read-only snapshot for diagnostics and real-keyboard acceptance tests.
Object.defineProperty(window, "dfaSnapshot", {
  value: () => (world ? structuredClone(world) : undefined),
  writable: false,
});
void prepareAssets();
requestAnimationFrame(loop);
