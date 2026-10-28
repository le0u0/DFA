extends Node2D

# Rows: left idle/walk/attack, then right idle/walk/attack. No body mirroring.
const BODIES := {
	"sword": preload("res://assets/characters/slayer/demo-atlas.png"),
	"gun": preload("res://assets/characters/gunner/demo-atlas.png"),
	"fists": preload("res://assets/characters/fighter/demo-atlas.png"),
	"staff": preload("res://assets/characters/mage/demo-atlas.png"),
	"cross": preload("res://assets/characters/priest/demo-atlas.png"),
}
const EQUIPMENT := {
	"sword": [preload("res://assets/weapons/sword-steel.png"), preload("res://assets/weapons/sword-cyan.png")],
	"gun": [preload("res://assets/weapons/pistol-0.png"), preload("res://assets/weapons/pistol-1.png")],
	"fists": [preload("res://assets/weapons/gauntlet-0.png"), preload("res://assets/weapons/gauntlet-1.png")],
	"staff": [preload("res://assets/weapons/staff-0.png"), preload("res://assets/weapons/staff-1.png")],
	"cross": [preload("res://assets/weapons/cross-0.png"), preload("res://assets/weapons/cross-1.png")],
}
const HANDS := [
	[Vector2(58, 92), Vector2(58, 92), Vector2(58, 92), Vector2(58, 92)],
	[Vector2(57, 78), Vector2(57, 78), Vector2(57, 78), Vector2(57, 78)],
	[Vector2(51, 41), Vector2(38, 78), Vector2(42, 94), Vector2(44, 86)],
	[Vector2(87, 93), Vector2(87, 93), Vector2(87, 93), Vector2(87, 93)],
	[Vector2(87, 84), Vector2(87, 84), Vector2(87, 84), Vector2(87, 84)],
	[Vector2(89, 41), Vector2(96, 78), Vector2(85, 94), Vector2(85, 86)],
]
var weapon_index := 0
var row := 3
var frame := 0
var clock := 0.0
var actor
var body: Texture2D
var equipment: Array
var weapon_kind := "sword"

func _ready() -> void:
	actor = get_parent()
	weapon_kind = actor.character.weapon
	body = BODIES[weapon_kind]
	equipment = EQUIPMENT[weapon_kind]
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _physics_process(delta: float) -> void:
	clock += delta
	var direction: float = actor.facing
	row = 3 if direction > 0 else 0
	var attacking: bool = actor.attack_kind != &""
	if actor.health <= 0:
		frame = 3
	elif attacking:
		row += 2
		var progress: float = clampf(actor.attack_elapsed / maxf(actor.attack_duration, 0.001), 0, 0.999)
		# Impact pose starts at the existing one-third strike time.
		frame = 0 if progress < 1.0 / 3.0 else 1 if progress < 0.55 else 2 if progress < 0.8 else 3
	elif actor.velocity.length() > 1 and actor.stun <= 0:
		row += 1
		frame = int(clock * (12 if actor.running else 8)) % 4
	else:
		frame = int(clock * 4) % 4
	position.y = -actor.jump_height
	modulate = Color.WHITE if actor.flash <= 0 else Color(1.7, 1.7, 1.7)
	if actor.health <= 0:
		modulate = Color(0.55, 0.55, 0.55)
	if actor.invulnerability > 0 and int(clock * 14) % 2 == 0:
		modulate.a = 0.5
	queue_redraw()

func cycle_weapon() -> void:
	weapon_index = (weapon_index + 1) % equipment.size()
	queue_redraw()

func _hand(offhand := false) -> Vector2:
	var right := row >= 3
	var action := row % 3
	if weapon_kind == "sword":
		return HANDS[row][frame] - Vector2(64, 112)
	# Pixel anchors authored against normalized body cells, not weapon bounds.
	var left: Array
	var facing_right: Array
	match weapon_kind:
		"gun":
			left = [Vector2(54, 92), Vector2(52, 84), [Vector2(59, 70), Vector2(36, 67), Vector2(36, 60), Vector2(46, 91)]]
			facing_right = [Vector2(85, 92), Vector2(85, 85), [Vector2(69, 70), Vector2(96, 67), Vector2(96, 60), Vector2(86, 91)]]
			if offhand:
				left = [Vector2(82, 92), Vector2(84, 86), [Vector2(67, 76), Vector2(79, 82), Vector2(79, 82), Vector2(84, 91)]]
				facing_right = [Vector2(48, 92), Vector2(49, 86), [Vector2(59, 76), Vector2(51, 82), Vector2(51, 82), Vector2(48, 91)]]
		"fists":
			left = [Vector2(47, 81), Vector2(47, 83), [Vector2(42, 69), Vector2(29, 67), Vector2(38, 89), Vector2(43, 79)]]
			facing_right = [Vector2(85, 81), Vector2(85, 83), [Vector2(87, 69), Vector2(101, 70), Vector2(94, 89), Vector2(87, 79)]]
			if offhand:
				left = [Vector2(73, 81), Vector2(79, 86), [Vector2(69, 78), Vector2(70, 71), Vector2(69, 72), Vector2(71, 79)]]
				facing_right = [Vector2(58, 81), Vector2(51, 86), [Vector2(61, 78), Vector2(64, 71), Vector2(54, 71), Vector2(59, 79)]]
		"staff":
			left = [Vector2(44, 86), Vector2(45, 81), [Vector2(55, 77), Vector2(38, 68), Vector2(43, 73), Vector2(55, 77)]]
			facing_right = [Vector2(77, 86), Vector2(82, 81), [Vector2(72, 77), Vector2(99, 68), Vector2(93, 73), Vector2(72, 77)]]
		_:
			left = [Vector2(48, 94), Vector2(41, 78), [Vector2(76, 39), Vector2(38, 61), Vector2(43, 90), Vector2(43, 86)]]
			facing_right = [Vector2(84, 94), Vector2(85, 78), [Vector2(55, 36), Vector2(90, 58), Vector2(93, 91), Vector2(89, 86)]]
	var anchors: Array = facing_right if right else left
	var hand: Vector2 = anchors[action] if action < 2 else anchors[action][frame]
	return hand - Vector2(64, 112)

func _draw_equipment(offhand := false) -> void:
	var hand := _hand(offhand)
	var facing_right := row >= 3
	var angle := (1.9 if facing_right else -1.9)
	if row % 3 == 2:
		angle = [0.15, 1.55, 2.6, 1.9][frame] * (1 if facing_right else -1)
	var rect := Rect2(-18, -54, 36, 72)
	match weapon_kind:
		"gun":
			angle = (PI / 2 if facing_right else -PI / 2) if row % 3 == 2 else (2.5 if facing_right else -2.5)
			# The revolver's grip sits to the right of its upward-pointing barrel.
			rect = Rect2(-14, -28, 18, 36)
		"fists":
			angle = 0
			rect = Rect2(-5, -7, 10, 12)
		"staff":
			angle = (0.18 if row % 3 == 2 else 0.5) * (1 if facing_right else -1)
			rect = Rect2(-18, -42, 36, 84)
		"cross":
			rect = Rect2(-32, -74, 64, 96)
	draw_set_transform(hand, angle)
	draw_texture_rect(equipment[weapon_index], rect, false)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	# Most grips sit behind the body hand; gauntlets cover the base glove.
	if weapon_kind != "fists":
		_draw_equipment()
		if weapon_kind == "gun":
			_draw_equipment(true)
	draw_texture_rect_region(body, Rect2(-64, -112, 128, 128), Rect2(frame * 128, row * 128, 128, 128))
	if weapon_kind == "fists":
		_draw_equipment()
		_draw_equipment(true)
