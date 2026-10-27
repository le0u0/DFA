if (process.argv.includes("--inspect") || process.argv.includes("--all")) {
  await import("./inspect.mjs");
  if (!process.argv.includes("--all")) process.exit(0);
}
// Real-keyboard acceptance run. Requires the bundled Playwright runtime or PLAYWRIGHT_MODULE.
import { createRequire } from "node:module";
import assert from "node:assert/strict";
const require = createRequire(import.meta.url);
const { chromium } = require(
  process.env.PLAYWRIGHT_MODULE ||
    "/Users/daphneo/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright",
);
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width: 1440, height: 960 } });
const errors = [];
page.on("pageerror", (e) => errors.push(e.message));
const target = process.env.DFA_URL || "http://127.0.0.1:5173";
try {
  await page.goto(target);
  await page.getByRole("heading", { name: "Choose your fighter" }).waitFor();
  for (const character of ["Male Slayer", "Male Gunner"]) {
    await page
      .getByRole("button", { name: new RegExp("Select " + character) })
      .click();
    await page.getByRole("button", { name: "Enter Mirkwood" }).click();
    await page.locator('[data-phase="playing"]').waitFor({ timeout: 10000 });
    await page.keyboard.press("Escape");
    await page.getByRole("heading", { name: "Paused" }).waitFor();
    await page.getByRole("button", { name: "Continue" }).click();
    const held = new Set();
    let frames = 0;
    // Read-only snapshot guides the keyboard driver. No state mutations, cheats or debug damage.
    while (frames++ < 1600) {
      const s = await page.evaluate(() => window.dfaSnapshot());
      if (s.phase !== "playing") break;
      const e = s.enemies.find((e) => e.hp > 0);
      const want = new Set();
      if (e) {
        let dx = e.x - s.player.x,
          dy = e.y - s.player.y;
        if (Math.abs(dx) < (character === "Male Slayer" ? 100 : 550))
          want.add("KeyX");
        if (Math.abs(dx) > 60 || Math.sign(dx) !== s.player.facing)
          want.add(dx > 0 ? "ArrowRight" : "ArrowLeft");
        if (Math.abs(dy) > 8) want.add(dy > 0 ? "ArrowDown" : "ArrowUp");
      } else {
        if (s.room === 3) {
          if (s.player.x < 760) want.add("ArrowRight");
          want.add("ArrowUp");
        } else want.add("ArrowRight");
      }
      for (const key of held)
        if (!want.has(key)) {
          await page.keyboard.up(key);
          held.delete(key);
        }
      for (const key of want)
        if (!held.has(key)) {
          await page.keyboard.down(key);
          held.add(key);
        }
      if (e && Math.abs(e.x - s.player.x) < 90 && frames % 8 === 0)
        await page.keyboard.press("z");
      if (
        e &&
        Math.abs(e.x - s.player.x) <
          (character === "Male Slayer" ? 160 : 550) &&
        frames % 10 === 0
      )
        await page.keyboard.press("a");
      await page.waitForTimeout(75);
    }
    for (const key of held) await page.keyboard.up(key);
    await page
      .getByRole("heading", { name: "Mirkwood cleared" })
      .waitFor({ timeout: 2000 });
    await page.screenshot({
      path: "/tmp/dfa-" + character.replaceAll(" ", "-") + "-clear.png",
    });
    await page.getByRole("button", { name: "Play again" }).click();
    await page.waitForFunction(
      () =>
        window.dfaSnapshot().player.hp === 400 &&
        window.dfaSnapshot().room === 0,
    );
    await page.keyboard.press("Escape");
    await page.getByRole("button", { name: "Choose fighter" }).click();
  }
  assert.deepEqual(errors, []);
  console.log(
    "PASS: both real-keyboard Mirkwood runs, pause/resume, no page errors",
  );
} finally {
  await browser.close();
}
