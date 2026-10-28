extends Node2D

signal hit(damage: int, direction: float, launch: float)
var victim: DemoFighter
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
	if is_instance_valid(victim) and victim.health > 0:
		var crossed := victim.position.x >= minf(previous_x, position.x) - 16 and victim.position.x <= maxf(previous_x, position.x) + 16
		if crossed and absf(position.y - victim.position.y) <= 34 and absf(height - victim.jump_height - 30) <= 30:
			hit.emit(damage, direction, launch)
			queue_free()
			return
	if remaining <= 0 or height < 0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	draw_line(Vector2(-direction * 14, -height), Vector2(0, -height), tint, 5)
	draw_circle(Vector2(0, -height), 5, tint.lightened(0.3))
