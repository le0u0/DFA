import type { InputFrame } from "./simulation";
const actions: Record<string, keyof InputFrame> = {
  KeyC: "jump",
  KeyZ: "skill1",
  KeyA: "skillA",
  KeyS: "skillS",
  Space: "skill2",
};
export class KeyboardInput {
  private held = new Set<string>();
  private pressed = new Set<string>();
  private lastTap = new Map<string, number>();
  private runKey = "";
  press(code: string, time: number) {
    if (this.held.has(code)) return;
    this.held.add(code);
    this.pressed.add(code);
    if (code === "ArrowLeft" || code === "ArrowRight") {
      const last = this.lastTap.get(code);
      if (last !== undefined && time - last < 260) this.runKey = code;
      this.lastTap.set(code, time);
    }
  }
  release(code: string) {
    this.held.delete(code);
    if (this.runKey === code) this.runKey = "";
  }
  clear() {
    this.held.clear();
    this.pressed.clear();
    this.lastTap.clear();
    this.runKey = "";
  }
  sample(): InputFrame {
    const v: InputFrame = {
      x:
        Number(this.held.has("ArrowRight")) -
        Number(this.held.has("ArrowLeft")),
      y: Number(this.held.has("ArrowDown")) - Number(this.held.has("ArrowUp")),
      run: !!this.runKey,
      attack: this.held.has("KeyX"),
      jump: false,
      skill1: false,
      skillA: false,
      skillS: false,
      skill2: false,
    };
    for (const [code, key] of Object.entries(actions))
      if (this.pressed.has(code)) (v[key] as boolean) = true;
    this.pressed.clear();
    return v;
  }
}
