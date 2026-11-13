extends Node2D

# Rows: left idle/walk/attack, then right idle/walk/attack. No body mirroring.
const BODIES := {
	"sword": preload("res://assets/characters/slayer/demo-atlas.png"),
}
const EQUIPMENT := {
	"sword": [preload("res://assets/weapons/sword-steel.png"), preload("res://assets/weapons/sword-cyan.png")],
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

func _hand() -> Vector2:
	return HANDS[row][frame] - Vector2(64, 112)

func _draw_equipment() -> void:
	var hand := _hand()
	var facing_right := row >= 3
	var angle := (1.9 if facing_right else -1.9)
	if row % 3 == 2:
		angle = [0.15, 1.55, 2.6, 1.9][frame] * (1 if facing_right else -1)
	var rect := Rect2(-18, -54, 36, 72)
	draw_set_transform(hand, angle)
	draw_texture_rect(equipment[weapon_index], rect, false)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	_draw_equipment()
	draw_texture_rect_region(body, Rect2(-64, -112, 128, 128), Rect2(frame * 128, row * 128, 128, 128))
