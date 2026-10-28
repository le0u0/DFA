extends RefCounted

# Authored encounters: introduction, elite test, then a boss with a recovery beat.
const LIST := [
	{"name": "1 · Mosswood Outskirts", "floor": Color("283d32"), "accent": Color("729451"),
	"rooms": [
		{"name": "Forest approach", "enemies": ["goblin", "goblin"]},
		{"name": "Sentinel's clearing", "enemies": ["sentinel", "goblin"]},
		{"name": "Root King's den", "enemies": ["root_king"]}]},
	{"name": "2 · Emberstone Ruins", "floor": Color("44302b"), "accent": Color("d38a50"),
	"rooms": [
		{"name": "Ash courtyard", "enemies": ["cinder", "cinder", "cinder"]},
		{"name": "Warden's gate", "enemies": ["warden", "cinder"]},
		{"name": "Furnace throne", "enemies": ["furnace_lord"]}]}
]
const ENEMIES := {
	"goblin": {"name": "Moss Goblin", "hp": 45, "damage": 7, "speed": 85.0, "reach": 105.0, "windup": 0.6, "cooldown": 1.6, "color": Color("79ab58"), "rank": "normal"},
	"sentinel": {"name": "Briar Sentinel", "hp": 130, "damage": 12, "speed": 105.0, "reach": 135.0, "windup": 0.7, "cooldown": 1.8, "color": Color("b7c95c"), "rank": "elite"},
	"root_king": {"name": "Root King", "hp": 300, "damage": 16, "speed": 75.0, "reach": 155.0, "windup": 0.85, "cooldown": 2.1, "color": Color("8ead58"), "rank": "boss", "special": "stomp"},
	"cinder": {"name": "Cinder Goblin", "hp": 65, "damage": 9, "speed": 110.0, "reach": 110.0, "windup": 0.55, "cooldown": 1.5, "color": Color("db8050"), "rank": "normal"},
	"warden": {"name": "Obsidian Warden", "hp": 175, "damage": 15, "speed": 95.0, "reach": 170.0, "windup": 0.8, "cooldown": 1.9, "color": Color("bc89cc"), "rank": "elite"},
	"furnace_lord": {"name": "Furnace Lord", "hp": 400, "damage": 20, "speed": 90.0, "reach": 175.0, "windup": 0.9, "cooldown": 2.2, "color": Color("f2a35b"), "rank": "boss", "special": "sweep"}
}
