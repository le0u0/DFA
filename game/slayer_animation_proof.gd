extends Node2D
## Visual-only animation player. Does not own movement, collision or damage.

const FixedModel := preload("res://game/slayer_model.gd")
var fixed_model := FixedModel.new()

const SWORDS := [preload("res://assets/weapons/sword-steel.png"), preload("res://assets/weapons/sword-cyan.png")]
const DATA_PATH := "res://assets/characters/slayer/animation-proof/animations.json"
var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
var action := "idle"
var facing := "right"
var frame := 0
var elapsed := 0.0
var finished := false
var repeat_attack := false
var weapon_index := 0
var show_anchors := false
var motion_seconds := 0.0
var motion_parameters: Dictionary = {}
var transition_from: Dictionary = {}
var transition_age := 1.0
var sampled_action := ""
var movement_speed := 0.0

func set_motion(value: String, direction: String, seconds: float, delta: float, speed := 0.0) -> void:
	if value != sampled_action:
		transition_from = motion_parameters.duplicate(true)
		# Combo boundaries already share a full-body pose. Other state changes
		# blend authored parameters before IK, so bones never shrink or stretch.
		transition_age = 1.0 if (sampled_action == "attack1" and value == "attack2") or (sampled_action == "attack2" and value == "attack3") else 0.0
		sampled_action = value
	transition_age += maxf(delta,0.0)
	action = value
	facing = direction
	motion_seconds = seconds
	movement_speed = speed
	var target: Dictionary = fixed_model.parameters(action,seconds,speed)
	if not transition_from.is_empty() and transition_age < 0.10:
		motion_parameters = fixed_model.blend(transition_from,target,smoothstep(0,0.10,transition_age))
	else:
		motion_parameters = target
	queue_redraw()

func current_pose() -> Dictionary:
	if motion_parameters.is_empty():
		return fixed_model.pose(action,facing,frame,data)
	return fixed_model.assemble(motion_parameters,facing)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

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
	motion_seconds = 0.0
	motion_parameters.clear()
	sampled_action = ""
	frame = 0
	elapsed = 0.0
	finished = false
	queue_redraw()

func seek(value: int) -> void:
	motion_parameters.clear()
	frame = wrapi(value, 0, clip()["durations"].size())
	elapsed = 0.0
	finished = false
	queue_redraw()

func advance(delta: float) -> void:
	if finished:
		return
	motion_seconds += maxf(delta,0.0)
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
	var total := 0.0
	for duration in durations:
		total += float(duration)
	var sample_seconds := fposmod(motion_seconds,total) if action.begins_with("attack") and repeat_attack else motion_seconds
	set_motion(action,facing,sample_seconds,delta)
	queue_redraw()

func hand_anchor() -> Vector2:
	return current_pose()["wrist"]

func sword_angle() -> float:
	return float(current_pose()["sword"])

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

func source_attack_time(seconds: float, duration: float, strike: float) -> float:
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
	return source_time

func frame_at_attack_time(seconds: float, duration: float, strike: float) -> int:
	return frame_at_time(source_attack_time(seconds,duration,strike) + 0.000001)

func _draw() -> void:
	var pose: Dictionary = current_pose()
	var sword: Texture2D = SWORDS[weapon_index] if weapon_index < SWORDS.size() else null
	fixed_model.draw(self, pose, sword, sword_angle())
	if show_anchors:
		draw_circle(pose["wrist"], 2, Color.YELLOW)
