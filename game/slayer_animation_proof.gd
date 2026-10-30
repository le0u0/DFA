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
	assert(data["clips"].has(value + "_" + facing))
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
			if clip()["loop"] or (action.begins_with("attack") and repeat_attack):
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

func frame_at_time(seconds: float, looping := false) -> int:
	var durations: Array = clip()["durations"]
	var total := 0.0
	for duration in durations:
		total += float(duration)
	var time := fposmod(seconds, total) if looping else maxf(seconds, 0.0)
	for index in range(durations.size()):
		if time < float(durations[index]):
			return index
		time -= float(durations[index])
	return durations.size() - 1

func frame_at_attack_time(seconds: float, duration: float, strike: float) -> int:
	# Preserve source order/repeated poses and relative delays on each side of
	# the existing damage event. This does not change the actor's combat clock.
	var durations: Array = clip()["durations"]
	var impact: int = clip()["impact_frame"]
	var total := 0.0
	var anticipation := 0.0
	for index in range(durations.size()):
		total += float(durations[index])
		if index < impact:
			anticipation += float(durations[index])
	var source_time: float
	if seconds < strike and anticipation > 0:
		source_time = seconds / maxf(strike, 0.001) * anticipation
	else:
		source_time = anticipation + (seconds - strike) / maxf(duration - strike, 0.001) * (total - anticipation)
	return frame_at_time(source_time + 0.000001)

func _draw() -> void:
	var hand := hand_anchor()
	if weapon_index < SWORDS.size():
		# Shared grip point for both swords. Body fingers cover the handle.
		draw_set_transform(hand, sword_angle())
		draw_texture_rect(SWORDS[weapon_index], Rect2(-12, -48, 24, 64), false)
		draw_set_transform(Vector2.ZERO)
	var row: int = clip()["row"]
	var column: int = clip()["cells"][frame] if clip().has("cells") else frame
	draw_texture_rect_region(ATLAS, Rect2(-64, -112, 128, 128), Rect2(column * 128, row * 128, 128, 128))
	# Guard/thrust windups carry the blade in front of the body. Drawing the
	# entire weapon behind the body made it disappear, then pop out at impact.
	# Only redraw the blade; keep the hilt under the body fingers.
	var front_blade := (action == "attack1" and frame < int(clip()["impact_frame"])) or (action == "dashattack" and frame <= 2)
	if front_blade and weapon_index < SWORDS.size():
		draw_set_transform(hand, sword_angle())
		draw_texture_rect_region(SWORDS[weapon_index], Rect2(-12, -48, 24, 64.0 * 2.0 / 3.0), Rect2(0, 0, 48, 64))
		draw_set_transform(Vector2.ZERO)
	if show_anchors:
		draw_line(Vector2(-5, 0), Vector2(5, 0), Color.CYAN)
		draw_line(Vector2(0, -5), Vector2(0, 5), Color.CYAN)
		draw_circle(hand, 2.0, Color.YELLOW)
