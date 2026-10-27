import { it, expect } from "vitest";
import { validateManifest } from "../src/game/assets";
it("rejects missing character animation instead of allowing invisible players", () => {
  expect(() =>
    validateManifest({
      image: "atlas.png",
      frames: {},
      animations: {},
      scenery: [],
    }),
  ).toThrow(/slayer-idle/);
});
