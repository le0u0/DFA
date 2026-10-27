import { it, expect } from "vitest";
import { KeyboardInput } from "../src/game/input";
it("maps fixed PC keys and consumes one-shot skills once", () => {
  const k = new KeyboardInput();
  k.press("ArrowRight", 0);
  k.press("KeyX", 0);
  k.press("KeyC", 0);
  k.press("KeyZ", 0);
  k.press("KeyA", 0);
  k.press("KeyS", 0);
  k.press("Space", 0);
  expect(k.sample()).toEqual({
    x: 1,
    y: 0,
    run: false,
    attack: true,
    jump: true,
    skill1: true,
    skillA: true,
    skillS: true,
    skill2: true,
  });
  expect(k.sample().jump).toBe(false);
});
it("requires release between taps and runs on a second horizontal tap", () => {
  const k = new KeyboardInput();
  k.press("ArrowRight", 0);
  k.press("ArrowRight", 100);
  expect(k.sample().run).toBe(false);
  k.release("ArrowRight");
  k.press("ArrowRight", 200);
  expect(k.sample().run).toBe(true);
});
it("clears held and buffered inputs on blur", () => {
  const k = new KeyboardInput();
  k.press("ArrowRight", 0);
  k.press("KeyZ", 0);
  k.clear();
  expect(k.sample().x).toBe(0);
  expect(k.sample().skill1).toBe(false);
});
