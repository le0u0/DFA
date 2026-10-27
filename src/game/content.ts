export type CharacterId = "slayer" | "gunner";
export type EnemyKind = "goblin" | "thrower" | "tau" | "boss";
export const WIDTH = 960;
export const HEIGHT = 540;
export const GROUND = { left: 45, right: 915, top: 300, bottom: 475 };
export const ROOMS = [
  {
    name: "Forest entrance",
    cell: "A2",
    exit: "right",
    enemies: ["goblin", "goblin", "thrower"],
  },
  {
    name: "Goblin trail",
    cell: "B2",
    exit: "right",
    enemies: ["goblin", "thrower", "goblin", "goblin"],
  },
  {
    name: "Deep woods",
    cell: "C2",
    exit: "right",
    enemies: ["tau", "goblin", "thrower"],
  },
  {
    name: "Beast approach",
    cell: "D2",
    exit: "up",
    enemies: ["tau", "thrower", "goblin"],
  },
  {
    name: "Tau Beast",
    cell: "D1",
    exit: "none",
    enemies: ["boss", "goblin", "thrower"],
  },
] as const;
export const CHARACTERS = {
  slayer: {
    name: "Male Slayer",
    subtitle: "Steel meets the darkness",
    weapon: "Katana",
    description:
      "Close the distance. Chain sword strikes and launch enemies into the air.",
    skills: [
      { key: "Z", name: "Upper Slash", cooldown: 3 },
      { key: "A", name: "Ghost Slash", cooldown: 5 },
      { key: "S", name: "Guard", cooldown: 4 },
    ],
  },
  gunner: {
    name: "Male Gunner",
    subtitle: "Never miss your moment",
    weapon: "Revolvers",
    description:
      "Control the distance. Fire from range and keep enemies away with a rising kick.",
    skills: [
      { key: "Z", name: "Jack Spike", cooldown: 3 },
      { key: "A", name: "Gatling Gun", cooldown: 5 },
      { key: "S", name: "Mach Kick", cooldown: 4 },
    ],
  },
} as const;
