import { GROUND, ROOMS, type CharacterId, type EnemyKind } from "./content";
export type { CharacterId } from "./content";
export interface InputFrame {
  x: number;
  y: number;
  run: boolean;
  attack: boolean;
  jump: boolean;
  skill1: boolean;
  skillA: boolean;
  skillS: boolean;
  skill2: boolean;
}
export type Action =
  | "idle"
  | "walk"
  | "run"
  | "attack"
  | "upper"
  | "special"
  | "kick"
  | "guard"
  | "hurt"
  | "jump"
  | "dead"
  | "windup"
  | "charge";
export type CooldownKey = "skill1" | "skillA" | "skillS";
export interface Entity {
  id: number;
  x: number;
  y: number;
  z: number;
  vz: number;
  facing: number;
  hp: number;
  maxHp: number;
  action: Action;
  actionTime: number;
  actionDuration: number;
  stun: number;
  invincible: number;
  vx: number;
  vy: number;
  moving: boolean;
}
export interface Player extends Entity {
  character: CharacterId;
  cooldowns: Record<CooldownKey, number>;
  combo: number;
  comboTimeout: number;
  attackFired: boolean;
  shotTimer: number;
  shots: number;
}
export interface Enemy extends Entity {
  kind: EnemyKind;
  cooldown: number;
  attackFired: boolean;
  targetX: number;
  targetY: number;
}
export interface Projectile {
  id: number;
  x: number;
  y: number;
  z: number;
  vx: number;
  life: number;
  damage: number;
  team: "player" | "enemy";
  hit: number[];
}
export interface Effect {
  id: number;
  kind: "hit" | "slash" | "shot" | "damage" | "dust" | "heal";
  x: number;
  y: number;
  z: number;
  life: number;
  maxLife: number;
  facing: number;
  text?: string;
  player?: boolean;
}
export interface World {
  player: Player;
  enemies: Enemy[];
  projectiles: Projectile[];
  effects: Effect[];
  room: number;
  phase: "playing" | "paused" | "victory" | "defeat";
  elapsed: number;
  kills: number;
  combo: number;
  comboTime: number;
  roomCleared: boolean;
  nextId: number;
  transition: number;
  shake: number;
}
const base = (id: number, x: number, y: number, hp: number): Entity => ({
  id,
  x,
  y,
  z: 0,
  vz: 0,
  facing: 1,
  hp,
  maxHp: hp,
  action: "idle",
  actionTime: 0,
  actionDuration: 0,
  stun: 0,
  invincible: 0,
  vx: 0,
  vy: 0,
  moving: false,
});
export function createWorld(character: CharacterId): World {
  const world: World = {
    player: {
      ...base(1, 125, 390, 400),
      character,
      cooldowns: { skill1: 0, skillA: 0, skillS: 0 },
      combo: 0,
      comboTimeout: 0,
      attackFired: false,
      shotTimer: 0,
      shots: 0,
    },
    enemies: [],
    projectiles: [],
    effects: [],
    room: 0,
    phase: "playing",
    elapsed: 0,
    kills: 0,
    combo: 0,
    comboTime: 0,
    roomCleared: false,
    nextId: 2,
    transition: 0.7,
    shake: 0,
  };
  enterRoom(world, 0);
  return world;
}
export function enterRoom(w: World, room: number): void {
  w.room = room;
  w.roomCleared = false;
  w.projectiles = [];
  w.effects = [];
  w.transition = 0.6;
  const p = w.player;
  p.cooldowns = { skill1: 0, skillA: 0, skillS: 0 };
  p.combo = 0;
  p.comboTimeout = 0;
  p.attackFired = false;
  p.shotTimer = 0;
  p.x = 125;
  p.y = 390;
  p.z = 0;
  p.vz = 0;
  p.vx = 0;
  p.vy = 0;
  p.action = "idle";
  p.actionTime = 0;
  p.actionDuration = 0;
  p.stun = 0;
  p.shots = 0;
  p.invincible = 0.8;
  w.enemies = ROOMS[room].enemies.map((kind, i) => {
    const hp =
      kind === "boss"
        ? 440
        : kind === "tau"
          ? 100
          : kind === "thrower"
            ? 45
            : 55;
    return {
      ...base(w.nextId++, 480 + i * 145, 350 + (i % 2) * 85, hp),
      kind,
      facing: -1,
      cooldown: 1 + i * 0.5,
      attackFired: false,
      targetX: 0,
      targetY: 0,
    };
  });
}
const clamp = (n: number, min: number, max: number) =>
  Math.max(min, Math.min(max, n));
function effect(
  w: World,
  kind: Effect["kind"],
  e: Entity,
  text?: string,
  player = false,
) {
  const life = kind === "damage" ? 0.75 : 0.24;
  w.effects.push({
    id: w.nextId++,
    kind,
    x: e.x,
    y: e.y,
    z: e.z,
    life,
    maxLife: life,
    facing: e.facing,
    text,
    player,
  });
}
function action(e: Entity, name: Action, duration: number) {
  e.action = name;
  e.actionTime = 0;
  e.actionDuration = duration;
}
function hurt(
  w: World,
  target: Entity,
  damage: number,
  facing: number,
  launch = 0,
) {
  if (target.hp <= 0 || target.invincible > 0) return;
  const guarding = target === w.player && target.action === "guard";
  target.hp = Math.max(
    0,
    target.hp - (guarding ? Math.ceil(damage * 0.15) : damage),
  );
  effect(
    w,
    "damage",
    target,
    String(guarding ? Math.ceil(damage * 0.15) : damage),
    target === w.player,
  );
  effect(w, "hit", target);
  w.shake = target === w.player ? 0.13 : 0.055;
  target.vx = facing * (guarding ? 25 : target === w.player ? 110 : 180);
  if (!guarding) {
    target.stun = target === w.player ? 0.25 : 0.32;
    action(target, "hurt", 0.25);
    if (launch) {
      target.vz = launch;
      target.z = Math.max(1, target.z);
    }
  }
  if (target === w.player) {
    target.invincible = 0.8;
  } else {
    w.combo++;
    w.comboTime = 2;
    if (target.hp === 0) {
      w.kills++;
      action(target, "dead", 0.6);
    }
  }
}
function melee(w: World, reach: number, damage: number, launch = 0) {
  const p = w.player;
  for (const e of w.enemies) {
    const dx = (e.x - p.x) * p.facing;
    if (
      dx >= -18 &&
      dx < reach &&
      Math.abs(e.y - p.y) < 35 &&
      Math.abs(e.z - p.z) < 100
    )
      hurt(w, e, damage, p.facing, launch);
  }
  effect(w, "slash", p);
}
function shoot(w: World, damage: number) {
  const p = w.player;
  w.projectiles.push({
    id: w.nextId++,
    x: p.x + p.facing * 35,
    y: p.y,
    z: p.z + 80,
    vx: p.facing * 820,
    life: 1.2,
    damage,
    team: "player",
    hit: [],
  });
  effect(w, "shot", p);
}
function tickEntity(e: Entity, dt: number) {
  e.actionTime += dt;
  e.stun = Math.max(0, e.stun - dt);
  e.invincible = Math.max(0, e.invincible - dt);
  if (e.z > 0 || e.vz > 0) {
    e.z += e.vz * dt;
    e.vz -= 850 * dt;
    if (e.z <= 0) {
      e.z = 0;
      e.vz = 0;
    }
  }
  e.x = clamp(e.x + e.vx * dt, GROUND.left, GROUND.right);
  e.vx *= Math.exp(-12 * dt);
}
export function stepWorld(w: World, input: InputFrame, elapsed: number): void {
  if (w.phase !== "playing") return;
  const dt = clamp(elapsed, 0, 1 / 30);
  w.elapsed += dt;
  w.transition = Math.max(0, w.transition - dt);
  w.shake = Math.max(0, w.shake - dt);
  w.comboTime -= dt;
  if (w.comboTime <= 0) w.combo = 0;
  const p = w.player;
  tickEntity(p, dt);
  p.comboTimeout -= dt;
  for (const k of Object.keys(p.cooldowns) as CooldownKey[])
    p.cooldowns[k] = Math.max(0, p.cooldowns[k] - dt);
  if (p.hp <= 0) {
    w.phase = "defeat";
    return;
  }
  if (p.actionDuration > 0 && p.actionTime >= p.actionDuration) {
    p.action = "idle";
    p.actionDuration = 0;
  }
  if (p.stun <= 0) {
    const free = p.actionDuration === 0;
    if (free) {
      p.moving = !!(input.x || input.y);
      if (input.x) p.facing = Math.sign(input.x);
      const speed = input.run ? 290 : 175;
      const norm = Math.hypot(input.x, input.y) || 1;
      p.x = clamp(
        p.x + (input.x / norm) * speed * dt,
        GROUND.left,
        GROUND.right,
      );
      p.y = clamp(
        p.y + (input.y / norm) * speed * 0.65 * dt,
        GROUND.top,
        GROUND.bottom,
      );
      p.action =
        p.z > 0 ? "jump" : p.moving ? (input.run ? "run" : "walk") : "idle";
      if (input.jump && p.z === 0) {
        p.vz = 370;
        p.z = 1;
        effect(w, "dust", p);
      }
      let skill: CooldownKey | undefined = input.skill1
        ? "skill1"
        : input.skillA
          ? "skillA"
          : input.skillS
            ? "skillS"
            : undefined;
      if (skill && p.cooldowns[skill] > 0) skill = undefined;
      if (skill && p.z < 2) {
        p.cooldowns[skill] =
          skill === "skill1" ? 3 : skill === "skillA" ? 5 : 4;
        p.attackFired = false;
        if (skill === "skill1") action(p, "upper", 0.42);
        else if (skill === "skillA") {
          action(p, "special", p.character === "gunner" ? 0.85 : 0.52);
          p.shots = 8;
          p.shotTimer = 0;
        } else
          action(
            p,
            p.character === "slayer" ? "guard" : "kick",
            p.character === "slayer" ? 1.1 : 0.38,
          );
      } else if (input.attack) {
        p.combo = p.comboTimeout > 0 ? (p.combo + 1) % 3 : 0;
        p.comboTimeout = 0.8;
        p.attackFired = false;
        action(p, "attack", p.character === "gunner" ? 0.25 : 0.3);
      }
    }
    if (
      !p.attackFired &&
      p.actionTime >= 0.085 &&
      ["attack", "upper", "special", "kick"].includes(p.action)
    ) {
      p.attackFired = true;
      if (p.action === "attack") {
        if (p.character === "gunner") shoot(w, 23);
        else
          melee(w, 112, 24 + (p.combo === 2 ? 8 : 0), p.combo === 2 ? 120 : 0);
      } else if (p.action === "upper")
        melee(w, p.character === "slayer" ? 115 : 95, 38, 350);
      else if (p.action === "kick") melee(w, 115, 48, 180);
      else if (p.character === "slayer") melee(w, 185, 80, 160);
    }
    if (p.action === "special" && p.character === "gunner" && p.shots > 0) {
      p.shotTimer -= dt;
      if (p.shotTimer <= 0) {
        shoot(w, 15);
        p.shots--;
        p.shotTimer = 0.09;
      }
    }
  }
  for (const e of w.enemies) {
    tickEntity(e, dt);
    e.cooldown -= dt;
    e.moving = false;
    if (e.hp <= 0) {
      e.action = "dead";
      continue;
    }
    if (e.stun > 0 || e.z > 0) continue;
    const dx = p.x - e.x,
      dy = p.y - e.y;
    e.facing = dx >= 0 ? 1 : -1;
    if (e.action === "windup") {
      if (e.actionTime >= e.actionDuration) {
        if (e.kind === "thrower") {
          w.projectiles.push({
            id: w.nextId++,
            x: e.x,
            y: e.y,
            z: 28,
            vx: e.facing * 310,
            life: 2.5,
            damage: 12,
            team: "enemy",
            hit: [],
          });
          action(e, "attack", 0.3);
        } else if (e.kind === "boss" && Math.abs(dx) > 110) {
          action(e, "charge", 0.55);
          e.vx = e.facing * 490;
        } else {
          if (
            Math.abs(dx) < (e.kind === "boss" ? 155 : 95) &&
            Math.abs(dy) < 36 &&
            p.z < 55
          )
            hurt(w, p, e.kind === "boss" ? 32 : 12, e.facing);
          action(e, "attack", 0.35);
        }
        e.cooldown = e.kind === "boss" ? 1.5 : 1.8;
      }
      continue;
    }
    if (e.action === "charge") {
      e.vx = e.facing * 430;
      if (Math.abs(dx) < 72 && Math.abs(dy) < 38 && p.z < 50)
        hurt(w, p, 30, e.facing);
      if (e.actionTime > e.actionDuration) {
        e.vx = 0;
        action(e, "idle", 0);
      }
      continue;
    }
    if (e.action === "attack" && e.actionTime < e.actionDuration) continue;
    const range = e.kind === "thrower" ? 360 : e.kind === "boss" ? 270 : 67;
    if (Math.abs(dx) < range && Math.abs(dy) < 28 && e.cooldown <= 0) {
      action(e, "windup", e.kind === "boss" ? 0.85 : 0.65);
      e.targetX = p.x;
      e.targetY = p.y;
    } else {
      const speed = e.kind === "boss" ? 66 : e.kind === "tau" ? 57 : 68;
      const sx = Math.abs(dx) > range * 0.8 ? Math.sign(dx) : 0;
      const sy = Math.abs(dy) > 6 ? Math.sign(dy) : 0;
      e.x = clamp(e.x + sx * speed * dt, GROUND.left, GROUND.right);
      e.y = clamp(e.y + sy * speed * 0.6 * dt, GROUND.top, GROUND.bottom);
      e.moving = !!(sx || sy);
      e.action = e.moving ? "walk" : "idle";
    }
  }
  for (const b of w.projectiles) {
    b.x += b.vx * dt;
    b.life -= dt;
    if (b.team === "player") {
      for (const e of w.enemies) {
        if (
          e.hp > 0 &&
          !b.hit.includes(e.id) &&
          Math.abs(b.x - e.x) < 40 &&
          Math.abs(b.y - e.y) < 30 &&
          Math.abs(b.z - e.z - 40) < 65
        ) {
          hurt(w, e, b.damage, Math.sign(b.vx));
          b.hit.push(e.id);
          b.life = 0;
          break;
        }
      }
    } else if (
      Math.abs(b.x - p.x) < 25 &&
      Math.abs(b.y - p.y) < 27 &&
      p.z < 45
    ) {
      hurt(w, p, b.damage, Math.sign(b.vx));
      b.life = 0;
    }
  }
  w.projectiles = w.projectiles.filter(
    (b) => b.life > 0 && b.x > -40 && b.x < 1000,
  );
  w.effects.forEach((f) => (f.life -= dt));
  w.effects = w.effects.filter((f) => f.life > 0);
  if (p.hp <= 0) {
    w.phase = "defeat";
    return;
  }
  w.roomCleared = w.enemies.every((e) => e.hp <= 0);
  if (w.roomCleared) {
    if (w.room === ROOMS.length - 1) {
      w.phase = "victory";
      return;
    }
    const exit = ROOMS[w.room].exit;
    if (
      (exit === "right" && p.x > 900) ||
      (exit === "up" && p.y < 308 && p.x > 720)
    ) {
      p.hp = Math.min(p.maxHp, p.hp + 30);
      enterRoom(w, w.room + 1);
    }
  }
  if (p.hp <= 0) w.phase = "defeat";
}
