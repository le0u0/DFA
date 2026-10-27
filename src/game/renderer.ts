import { WIDTH, HEIGHT, GROUND, ROOMS } from "./content";
import type { World, Entity, Enemy, Player } from "./simulation";
import type { Assets } from "./assets";

export class Renderer {
  private ctx: CanvasRenderingContext2D;
  constructor(
    private canvas: HTMLCanvasElement,
    private assets: Assets,
  ) {
    const ctx = canvas.getContext("2d", { alpha: false });
    if (!ctx) throw new Error("This browser does not support Canvas 2D.");
    this.ctx = ctx;
    ctx.imageSmoothingEnabled = false;
  }
  private scenery(
    role: string,
    x: number,
    y: number,
    width?: number,
    height?: number,
  ) {
    const image = this.assets.scenery.get(role);
    if (image)
      this.ctx.drawImage(
        image,
        x,
        y,
        width ?? image.width,
        height ?? image.height,
      );
  }
  draw(w: World, time: number, reducedMotion = false) {
    const c = this.ctx;
    c.save();
    c.clearRect(0, 0, WIDTH, HEIGHT);
    c.fillStyle = "#101c19";
    c.fillRect(0, 0, WIDTH, HEIGHT);
    if (w.shake > 0 && !reducedMotion)
      c.translate(Math.sin(time * 91) * 2, Math.cos(time * 71));
    this.scenery("scene", 0, 0, WIDTH, HEIGHT);
    // One sourced original forest scene; no generated scenery substitute.
    const exit = ROOMS[w.room].exit;
    if (w.roomCleared && exit !== "none") {
      const x = exit === "right" ? 921 : 790,
        y = exit === "right" ? 385 : 302;
      c.save();
      c.translate(x, y);
      c.fillStyle = "#e4c27b";
      c.globalAlpha = 0.8 + 0.2 * Math.sin(time * 4);
      c.beginPath();
      if (exit === "right") {
        c.moveTo(-10, -15);
        c.lineTo(6, 0);
        c.lineTo(-10, 15);
      } else {
        c.moveTo(-15, 8);
        c.lineTo(0, -7);
        c.lineTo(15, 8);
      }
      c.closePath();
      c.fill();
      c.restore();
      this.text(
        "NEXT",
        exit === "right" ? 876 : 765,
        exit === "right" ? 422 : 280,
        12,
        "#ffe1a4",
      );
    }
    const entities: Entity[] = [...w.enemies, w.player];
    entities.sort((a, b) => a.y - b.y);
    for (const e of entities) {
      if (e.hp <= 0 && e.actionTime > 0.6) continue;
      this.entity(e, w, time);
    }
    for (const b of w.projectiles) {
      c.fillStyle = b.team === "player" ? "#ffe0a3" : "#b5a394";
      c.beginPath();
      c.ellipse(
        b.x,
        b.y - b.z,
        b.team === "player" ? 12 : 7,
        b.team === "player" ? 2 : 6,
        0,
        0,
        Math.PI * 2,
      );
      c.fill();
    }
    for (const f of w.effects) {
      const t = 1 - f.life / f.maxLife;
      c.save();
      c.globalAlpha = Math.min(1, f.life * 8);
      if (f.kind === "damage") {
        this.text(
          f.text ?? "",
          f.x,
          f.y - f.z - 75 - t * 30,
          f.player ? 18 : 20,
          f.player ? "#ff7f71" : "#fff5d3",
          true,
        );
      } else if (f.kind === "slash") {
        c.translate(f.x, f.y - f.z - 35);
        c.scale(f.facing, 1);
        c.strokeStyle = w.player.action === "special" ? "#b7b4ff" : "#ffe8b9";
        c.lineWidth = 3 * (1 - t) + 1;
        c.beginPath();
        c.ellipse(25, 0, 75 * (0.5 + t * 0.5), 44, -0.4, -1.6, 1.4);
        c.stroke();
      } else if (f.kind === "hit") {
        c.strokeStyle = "#ffecb2";
        c.lineWidth = 2;
        for (let j = 0; j < 5; j++) {
          const a = j * Math.PI * 0.4;
          c.beginPath();
          c.moveTo(f.x + Math.cos(a) * 5, f.y - f.z - 35 + Math.sin(a) * 5);
          c.lineTo(
            f.x + Math.cos(a) * (10 + t * 25),
            f.y - f.z - 35 + Math.sin(a) * (10 + t * 25),
          );
          c.stroke();
        }
      } else if (f.kind === "shot") {
        c.fillStyle = "#ffe8ac";
        c.beginPath();
        c.arc(f.x + f.facing * 45, f.y - f.z - 80, 7 * (1 - t), 0, Math.PI * 2);
        c.fill();
      }
      c.restore();
    }
    const boss = w.enemies.find((e) => e.kind === "boss" && e.hp > 0);
    if (boss) {
      c.fillStyle = "rgba(9,9,10,.8)";
      c.fillRect(262, 64, 436, 40);
      this.text("TAU BEAST", 480, 79, 12, "#e8d6b5", true);
      c.fillStyle = "#45282a";
      c.fillRect(275, 88, 410, 5);
      c.fillStyle = "#c45549";
      c.fillRect(275, 88, (410 * boss.hp) / boss.maxHp, 5);
    }
    if (w.combo > 1) this.text(`${w.combo} HIT`, 875, 160, 24, "#f6d38e", true);
    if (w.transition > 0) {
      c.fillStyle = `rgba(4,7,5,${w.transition * 0.65})`;
      c.fillRect(0, 0, WIDTH, HEIGHT);
      this.text(ROOMS[w.room].name, 480, 230, 27, "#ffe8b9", true);
    }
    c.restore();
  }
  private text(
    text: string,
    x: number,
    y: number,
    size: number,
    color: string,
    center = false,
  ) {
    const c = this.ctx;
    c.font = `600 ${size}px system-ui`;
    c.textAlign = center ? "center" : "left";
    c.lineWidth = 3;
    c.strokeStyle = "rgba(0,0,0,.7)";
    c.strokeText(text, x, y);
    c.fillStyle = color;
    c.fillText(text, x, y);
  }
  private entity(e: Entity, w: World, time: number) {
    const c = this.ctx,
      isPlayer = e === w.player,
      enemy = e as Enemy,
      p = e as Player;
    const name = isPlayer
      ? p.character
      : enemy.kind === "boss"
        ? "tau"
        : enemy.kind === "thrower"
          ? "goblin"
          : enemy.kind;
    const action =
      e.action === "run"
        ? "walk"
        : e.action === "windup"
          ? "idle"
          : e.action === "attack" &&
              isPlayer &&
              p.character === "slayer" &&
              p.combo > 0
            ? "attack" + (p.combo + 1)
            : e.action;
    const anim =
      this.assets.manifest.animations[`${name}-${action}`] ??
      this.assets.manifest.animations[`${name}-attack`] ??
      this.assets.manifest.animations[`${name}-idle`];
    if (!anim?.length) return;
    const index = ["idle", "walk"].includes(action)
      ? Math.floor(time * (action === "walk" ? 11 : 5)) % anim.length
      : Math.min(
          anim.length - 1,
          Math.floor((e.actionTime / (e.actionDuration || 0.4)) * anim.length),
        );
    const f = this.assets.manifest.frames[anim[index]];
    if (!f) return;
    const scale = isPlayer
      ? 1.15
      : enemy.kind === "boss"
        ? 1.45
        : enemy.kind === "tau"
          ? 1.1
          : 1.05;
    c.save();
    c.fillStyle = "rgba(1,5,4,.42)";
    c.beginPath();
    c.ellipse(
      e.x,
      e.y + 3,
      (isPlayer ? 23 : enemy.kind === "boss" ? 44 : 21) * (1 - e.z / 500),
      7,
      0,
      0,
      Math.PI * 2,
    );
    c.fill();
    if (e.action === "windup") {
      c.strokeStyle = "#f1ad64";
      c.lineWidth = 2;
      c.beginPath();
      c.ellipse(
        e.x,
        e.y,
        enemy.kind === "boss" ? 82 : 37,
        13,
        0,
        0,
        Math.PI * 2,
      );
      c.stroke();
    }
    c.translate(Math.round(e.x), Math.round(e.y - e.z));
    // The community Gunner sheet faces left; normalize it to world facing.
    c.scale(e.facing * scale * (name === "gunner" ? -1 : 1), scale);
    if (e.hp <= 0) c.globalAlpha = Math.max(0, 1 - e.actionTime / 0.6);
    else if (isPlayer && e.invincible > 0)
      c.globalAlpha = Math.floor(time * 16) % 2 ? 0.5 : 1;
    c.drawImage(this.assets.atlas, f.x, f.y, f.w, f.h, -f.ox, -f.oy, f.w, f.h);
    c.restore();
    if (!isPlayer && e.hp > 0 && e.hp < e.maxHp) {
      c.fillStyle = "#211e1c";
      c.fillRect(e.x - 24, e.y - e.z - 95 * scale, 48, 4);
      c.fillStyle = "#de9e65";
      c.fillRect(e.x - 24, e.y - e.z - 95 * scale, (48 * e.hp) / e.maxHp, 4);
    }
    if (isPlayer) {
      this.text("1P", e.x, e.y - e.z - 145, 11, "#f9da9d", true);
    }
  }
  portrait(character: "slayer" | "gunner", canvas: HTMLCanvasElement) {
    const c = canvas.getContext("2d");
    if (!c) return;
    c.imageSmoothingEnabled = false;
    const anim = this.assets.manifest.animations[character + "-idle"];
    if (!anim?.length) return;
    const f = this.assets.manifest.frames[anim[0]];
    c.clearRect(0, 0, canvas.width, canvas.height);
    c.save();
    c.translate(canvas.width / 2, canvas.height - 12);
    const scale = Math.min(
      (canvas.width - 24) / f.w,
      (canvas.height - 24) / Math.max(f.h, f.oy),
    );
    c.scale(scale, scale);
    c.drawImage(this.assets.atlas, f.x, f.y, f.w, f.h, -f.ox, -f.oy, f.w, f.h);
    c.restore();
  }
}
