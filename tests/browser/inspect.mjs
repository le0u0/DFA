import { createRequire } from "node:module";
import assert from "node:assert/strict";
const { chromium } = createRequire(import.meta.url)(
  process.env.PLAYWRIGHT_MODULE ||
    "/Users/daphneo/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright",
);
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width: 1440, height: 960 } });
await page.goto("http://127.0.0.1:5173");
await page.waitForFunction(
  () => !document.querySelector("#start-button").disabled,
);
await page.screenshot({ path: "/tmp/dfa-selection.png", fullPage: true });
await page.getByRole("button", { name: "Enter Mirkwood" }).click();
await page.waitForTimeout(900);
await page.screenshot({ path: "/tmp/dfa-combat.png", fullPage: true });
const timings = await page.evaluate(
  () =>
    new Promise((resolve) => {
      let last = performance.now(),
        values = [];
      function frame(now) {
        values.push(now - last);
        last = now;
        if (values.length < 180) requestAnimationFrame(frame);
        else {
          values.sort((a, b) => a - b);
          resolve({ median: values[90], p95: values[171], max: values[179] });
        }
      }
      requestAnimationFrame(frame);
    }),
);
await page.keyboard.down("ArrowRight");
await page.waitForTimeout(60);
await page.evaluate(() => window.dispatchEvent(new Event("blur")));
await page.getByRole("heading", { name: "Paused", exact: true }).waitFor();
await page.keyboard.press("Escape");
await page.locator('[data-phase="playing"]').waitFor();
const pausedX = await page.evaluate(() => window.dfaSnapshot().player.x);
await page.waitForTimeout(200);
assert.equal(await page.evaluate(() => window.dfaSnapshot().player.x), pausedX);
await page.keyboard.up("ArrowRight");
console.log({ timings, focusPause: true, heldInputReleased: true });
await page.getByRole("button", { name: "Pause game" }).click();
await page.getByRole("button", { name: "Restart Mirkwood" }).click();
await page.waitForFunction(
  () => window.dfaSnapshot()?.phase === "defeat",
  {},
  { timeout: 90000 },
);
await page.getByRole("button", { name: "Retry Mirkwood" }).click();
await page.waitForFunction(
  () =>
    window.dfaSnapshot().player.hp === 400 && window.dfaSnapshot().room === 0,
);
console.log("PASS defeat/retry with real enemy damage");
await page.setViewportSize({ width: 390, height: 844 });
await page.screenshot({ path: "/tmp/dfa-mobile.png", fullPage: true });
await page.route("**/assets/manifest.json", (route) =>
  route.fulfill({ status: 404, body: "missing" }),
);
await page.reload();
await page
  .getByRole("status")
  .filter({ hasText: "Original asset pack is missing" })
  .waitFor();
assert.equal(
  await page.getByRole("button", { name: "Enter Mirkwood" }).isDisabled(),
  true,
);
await page.unroute("**/assets/manifest.json");
await page.getByRole("button", { name: "Retry loading assets" }).click();
await page.waitForFunction(
  () => !document.querySelector("#start-button").disabled,
);
console.log("PASS missing-asset error and recovery");
await browser.close();
