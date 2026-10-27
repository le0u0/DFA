import { describe, it, expect } from "vitest";
import {
  createWorld,
  stepWorld,
  enterRoom,
  type InputFrame,
} from "../src/game/simulation";
const idle: InputFrame = {
  x: 0,
  y: 0,
  run: false,
  attack: false,
  jump: false,
  skill1: false,
  skillA: false,
  skillS: false,
  skill2: false,
};
const tick = (
  w: ReturnType<typeof createWorld>,
  input: Partial<InputFrame> = {},
  seconds = 1 / 60,
) => stepWorld(w, { ...idle, ...input }, seconds);
describe("Mirkwood combat", () => {
  for (const character of ["slayer", "gunner"] as const) {
    it(`${character} damages a facing target in its lane`, () => {
      const w = createWorld(character);
      const e = w.enemies[0];
      e.x = w.player.x + 65;
      e.y = w.player.y;
      const hp = e.hp;
      tick(w, { attack: true });
      for (let n = 0; n < 18; n++) tick(w);
      expect(e.hp).toBeLessThan(hp);
    });
    it(`${character} cannot hit another lane or an enemy behind it`, () => {
      const w = createWorld(character);
      w.enemies.forEach((e, i) => {
        e.x = w.player.x + (i ? -55 : 65);
        e.y = w.player.y + (i ? 0 : 120);
        e.cooldown = 100;
      });
      const hp = w.enemies.map((e) => e.hp);
      tick(w, { attack: true });
      for (let n = 0; n < 18; n++) tick(w);
      expect(w.enemies.map((e) => e.hp)).toEqual(hp);
    });
    it(`${character} skill cooldown rejects repeated activation`, () => {
      const w = createWorld(character);
      tick(w, { skill1: true });
      const first = w.player.cooldowns.skill1;
      tick(w, { skill1: true });
      expect(w.player.cooldowns.skill1).toBeLessThan(first);
      expect(w.player.cooldowns.skill1).toBeGreaterThan(1);
    });
    it(`${character} completes every room using real attacks`, () => {
      const w = createWorld(character);
      for (let frame = 0; frame < 24000 && w.phase === "playing"; frame++) {
        const e = w.enemies.find((e) => e.hp > 0);
        if (e) {
          const dx = e.x - w.player.x,
            dy = e.y - w.player.y;
          tick(w, {
            x:
              Math.abs(dx) > 60 || Math.sign(dx) !== w.player.facing
                ? Math.sign(dx)
                : 0,
            y: Math.abs(dy) > 8 ? Math.sign(dy) : 0,
            attack: Math.abs(dx) < (character === "slayer" ? 100 : 550),
            skill1: Math.abs(dx) < 90,
            skillA: Math.abs(dx) < (character === "slayer" ? 160 : 550),
            skillS: false,
          });
        } else {
          const exit = w.room === 3 ? "up" : "right";
          tick(w, {
            x: exit === "right" || w.player.x < 760 ? 1 : 0,
            y: exit === "up" ? -1 : 0,
            run: true,
          });
        }
      }
      expect(w.phase).toBe("victory");
      expect(w.room).toBe(4);
    });
  }
  it("locks room exits while enemies are alive", () => {
    const w = createWorld("slayer");
    w.player.x = 950;
    tick(w, { x: 1 });
    expect(w.room).toBe(0);
  });
  it("clears transient combat state on room entry", () => {
    const w = createWorld("gunner");
    tick(w, { skill1: true });
    w.player.cooldowns.skillA = 4;
    w.player.cooldowns.skillS = 3;
    w.enemies.forEach((e) => (e.hp = 0));
    enterRoom(w, 1);
    expect(w.projectiles).toHaveLength(0);
    expect(w.player.action).toBe("idle");
    expect(w.room).toBe(1);
    expect(w.player.cooldowns.skill1).toBe(0);
    expect(w.player.cooldowns.skillA).toBe(0);
    expect(w.player.cooldowns.skillS).toBe(0);
  });
  it("caps large deltas rather than teleporting", () => {
    const w = createWorld("slayer");
    const x = w.player.x;
    tick(w, { x: 1 }, 5);
    expect(w.player.x - x).toBeLessThan(20);
  });
  it("jump returns to ground and can evade low attacks", () => {
    const w = createWorld("slayer");
    tick(w, { jump: true });
    expect(w.player.vz).toBeGreaterThan(0);
    for (let i = 0; i < 120; i++) tick(w);
    expect(w.player.z).toBe(0);
  });
  it("new runs reset health, cooldowns, enemies and projectiles", () => {
    const w = createWorld("gunner");
    w.player.hp = 0;
    tick(w);
    expect(w.phase).toBe("defeat");
    const next = createWorld("gunner");
    expect(next.player.hp).toBe(next.player.maxHp);
    expect(next.room).toBe(0);
    expect(next.projectiles).toHaveLength(0);
    expect(next.player.cooldowns.skill1).toBe(0);
  });
  it("paused worlds do not advance", () => {
    const w = createWorld("slayer");
    w.phase = "paused";
    const x = w.player.x;
    tick(w, { x: 1, attack: true });
    expect(w.player.x).toBe(x);
    expect(w.elapsed).toBe(0);
  });
});
it("fatal damage takes priority over a simultaneous final kill", () => {
  const w = createWorld("gunner");
  enterRoom(w, 4);
  w.player.hp = 1;
  w.player.invincible = 0;
  w.player.x = 500;
  w.player.y = 390;
  w.enemies.forEach((e) => {
    e.hp = 0;
    e.cooldown = 100;
  });
  const e = w.enemies[0];
  e.hp = 1;
  e.x = 650;
  e.y = 390;
  w.projectiles = [
    {
      id: 900,
      x: 640,
      y: 390,
      z: 44,
      vx: 820,
      life: 1,
      damage: 30,
      team: "player",
      hit: [],
    },
    {
      id: 901,
      x: 505,
      y: 390,
      z: 28,
      vx: -310,
      life: 1,
      damage: 12,
      team: "enemy",
      hit: [],
    },
  ];
  tick(w);
  expect(e.hp).toBe(0);
  expect(w.player.hp).toBe(0);
  expect(w.phase).toBe("defeat");
});
it("an unlocked room exit cannot heal a lethally hit player", () => {
  const w = createWorld("slayer");
  w.enemies.forEach((e) => (e.hp = 0));
  w.player.hp = 1;
  w.player.invincible = 0;
  w.player.x = 910;
  w.player.y = 390;
  w.projectiles = [
    {
      id: 900,
      x: 915,
      y: 390,
      z: 28,
      vx: -310,
      life: 1,
      damage: 12,
      team: "enemy",
      hit: [],
    },
  ];
  tick(w, { x: 1 });
  expect(w.player.hp).toBe(0);
  expect(w.phase).toBe("defeat");
  expect(w.room).toBe(0);
});
