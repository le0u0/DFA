extends Node2D

signal hit_target(victim: DemoFighter, damage: int, direction: float, launch: float)
var victims: Array[DemoFighter] = []
var direction := 1.0
var speed := 850.0
var remaining := 700.0
var height := 40.0
var vertical_speed := 0.0
var damage := 14
var launch := 0.0
var tint := Color.GOLD

func _physics_process(delta: float) -> void:
	var travel := minf(speed * delta, remaining)
	var previous_x := position.x
	position.x += direction * travel
	height += vertical_speed * delta
	remaining -= travel
	var first: DemoFighter
	var nearest := INF
	for candidate in victims:
		if not is_instance_valid(candidate) or candidate.health <= 0:
			continue
		var crossed := candidate.position.x >= minf(previous_x, position.x) - 16 and candidate.position.x <= maxf(previous_x, position.x) + 16
		var distance := (candidate.position.x - previous_x) * direction
		if crossed and absf(position.y - candidate.position.y) <= 34 and absf(height - candidate.jump_height - 30) <= 30 and distance < nearest:
			first = candidate
			nearest = distance
	if first != null:
		hit_target.emit(first, damage, direction, launch)
		queue_free()
		return
	if remaining <= 0 or height < 0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	draw_line(Vector2(-direction * 14, -height), Vector2(0, -height), tint, 5)
	draw_circle(Vector2(0, -height), 5, tint.lightened(0.3))
