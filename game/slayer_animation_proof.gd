extends Node2D
## Visual-only animation player. Does not own movement, collision or damage.

const ATLAS := preload("res://assets/characters/slayer/animation-proof/body-atlas.png")
const SWORDS := [preload("res://assets/weapons/sword-steel.png"), preload("res://assets/weapons/sword-cyan.png")]
const DATA_PATH := "res://assets/characters/slayer/animation-proof/animations.json"
var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
var action := "idle"
var facing := "right"
var frame := 0
var elapsed := 0.0
var finished := false
var repeat_attack := true
var weapon_index := 0
var show_anchors := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func clip() -> Dictionary:
	return data["clips"][action + "_" + facing]

func select_action(value: String) -> void:
	assert(value in ["idle", "walk", "attack"])
	action = value
	restart()

func set_facing(value: String) -> void:
	assert(value in ["left", "right"])
	facing = value
	restart()

func restart() -> void:
	frame = 0
	elapsed = 0.0
	finished = false
	queue_redraw()

func seek(value: int) -> void:
	frame = wrapi(value, 0, clip()["durations"].size())
	elapsed = 0.0
	finished = false
	queue_redraw()

func advance(delta: float) -> void:
	if finished:
		return
	elapsed += maxf(delta, 0.0)
	var durations: Array = clip()["durations"]
	while elapsed >= float(durations[frame]):
		elapsed -= float(durations[frame])
		if frame == durations.size() - 1:
			if clip()["loop"] or (action == "attack" and repeat_attack):
				frame = 0
			else:
				finished = true
				elapsed = 0.0
				break
		else:
			frame += 1
	queue_redraw()

func hand_anchor() -> Vector2:
	var point: Array = clip()["hands"][frame]
	return Vector2(point[0], point[1]) - Vector2(64, 112)

func sword_angle() -> float:
	return float(clip()["sword_angles"][frame])

func _draw() -> void:
	var hand := hand_anchor()
	if weapon_index < SWORDS.size():
		# Shared grip point for both swords. Body fingers cover the handle.
		draw_set_transform(hand, sword_angle())
		draw_texture_rect(SWORDS[weapon_index], Rect2(-12, -48, 24, 64), false)
		draw_set_transform(Vector2.ZERO)
	var row: int = clip()["row"]
	draw_texture_rect_region(ATLAS, Rect2(-64, -112, 128, 128), Rect2(frame * 128, row * 128, 128, 128))
	if show_anchors:
		draw_line(Vector2(-5, 0), Vector2(5, 0), Color.CYAN)
		draw_line(Vector2(0, -5), Vector2(0, 5), Color.CYAN)
		draw_circle(hand, 2.0, Color.YELLOW)
