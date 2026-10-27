export interface SpriteFrame {
  x: number;
  y: number;
  w: number;
  h: number;
  ox: number;
  oy: number;
}
export interface AssetManifest {
  image: string;
  frames: Record<string, SpriteFrame>;
  animations: Record<string, string[]>;
  scenery: { file: string; role: string }[];
}
export interface Assets {
  manifest: AssetManifest;
  atlas: HTMLImageElement;
  scenery: Map<string, HTMLImageElement>;
}
export function loadImage(url: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.onload = () => resolve(image);
    image.onerror = () => reject(new Error(`Cannot load ${url}`));
    image.src = url;
  });
}
export function validateManifest(manifest: AssetManifest): void {
  for (const name of ["slayer", "gunner", "goblin", "tau"])
    for (const action of ["idle", "walk", "attack", "hurt", "dead", "jump"]) {
      const key = `${name}-${action}`,
        frames = manifest.animations[key];
      if (!frames?.length || frames.some((frame) => !manifest.frames[frame]))
        throw new Error(
          `Original asset pack is incomplete: ${key}. See README.md.`,
        );
    }
  for (const role of ["scene"])
    if (!manifest.scenery.some((item) => item.role === role))
      throw new Error(`Original scenery layer missing: ${role}`);
}
export async function loadAssets(): Promise<Assets> {
  const response = await fetch(
    `${import.meta.env.BASE_URL}assets/manifest.json`,
  );
  if (!response.ok)
    throw new Error(
      "Original asset pack is missing. See README.md for asset preparation.",
    );
  const manifest: AssetManifest = await response.json();
  validateManifest(manifest);
  const base = `${import.meta.env.BASE_URL}assets/`;
  const [atlas, scenery] = await Promise.all([
    loadImage(base + manifest.image),
    Promise.all(
      manifest.scenery.map(
        async (item) => [item.role, await loadImage(base + item.file)] as const,
      ),
    ),
  ]);
  return { manifest, atlas, scenery: new Map(scenery) };
}
