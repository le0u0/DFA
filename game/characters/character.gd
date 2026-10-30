extends Resource
class_name DemoCharacter

@export var display_name := "Slayer"
@export var description := "Sword combo"
@export var weapon := "sword"
@export var tint := Color(0.38, 0.65, 0.95)
@export var damage := 16
@export var finisher_damage := 24
@export var reach := 105.0
@export var attack_duration := 0.28
@export var combo_durations := PackedFloat32Array()
@export var combo_strike_times := PackedFloat32Array()
@export var chain_basic_attacks := false
@export var running_attack_duration := 0.0
@export var running_attack_strike_time := 0.0
@export var heavy_name := "Upward Slash"
@export var heavy_damage := 35
@export var heavy_reach := 145.0
@export var heavy_duration := 0.45
@export var heavy_cooldown := 1.1
@export var launch := 340.0
@export var projectile_speed := 0.0
@export var radial_heavy := false

func attack_timing(kind: StringName, stage: int) -> Vector2:
	if kind == &"dash" and running_attack_duration > 0:
		return Vector2(running_attack_duration, running_attack_strike_time)
	if kind == &"basic" and stage > 0 and stage <= combo_durations.size() and stage <= combo_strike_times.size():
		return Vector2(combo_durations[stage - 1], combo_strike_times[stage - 1])
	return Vector2(attack_duration, attack_duration / 3.0)
