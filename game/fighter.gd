extends CharacterBody2D
class_name DemoFighter

signal strike(attacker: DemoFighter, damage: int, reach: float, launch: float)
signal hurt(damage: int)
signal defeated

const FLOOR_BOUNDS := Rect2(80, 235, 1120, 400)
@export var character: DemoCharacter = preload("res://game/characters/slayer.tres")
var is_player := false
var immortal := false
var ai_enabled := true
var target: DemoFighter
var facing := 1.0
var health := 100
var jump_height := 0.0
var jump_velocity := 0.0
var stun := 0.0
var invulnerability := 0.0
var knockback := Vector2.ZERO
var dash_remaining := 0.0
var dash_cooldown := 0.0
var heavy_cooldown := 0.0
var attack_kind: StringName = &""
var attack_elapsed := 0.0
var attack_duration := 0.0
var strike_time := 0.0
var strike_fired := false
var attack_buffer := 0.0
var heavy_buffer := 0.0
var combo := 0
var combo_timeout := 0.0
var ai_cooldown := 0.8
var flash := 0.0
var last_direction := 0.0
var last_tap := -10.0
var running := false

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 1
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 13.0
	shape.shape = circle
	shape.position = Vector2(0, -8)
	add_child(shape)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if health <= 0:
		return
	stun = maxf(0, stun - delta)
	invulnerability = maxf(0, invulnerability - delta)
	dash_cooldown = maxf(0, dash_cooldown - delta)
	heavy_cooldown = maxf(0, heavy_cooldown - delta)
	ai_cooldown = maxf(0, ai_cooldown - delta)
	combo_timeout = maxf(0, combo_timeout - delta)
	flash = maxf(0, flash - delta)
	attack_buffer = maxf(0, attack_buffer - delta)
	heavy_buffer = maxf(0, heavy_buffer - delta)
	if jump_height > 0 or jump_velocity > 0:
		jump_height = maxf(0, jump_height + jump_velocity * delta)
		jump_velocity -= 1050.0 * delta
		if jump_height == 0:
			jump_velocity = 0
	collision_mask = 0 if jump_height > 18 else 1
	velocity = Vector2.ZERO
	if is_player:
		_player_input()
	elif ai_enabled:
		_enemy_input()
	if dash_remaining > 0:
		dash_remaining = maxf(0, dash_remaining - delta)
		velocity.x = facing * 650.0
	if attack_kind != &"":
		attack_elapsed += delta
		if attack_elapsed >= strike_time and not strike_fired:
			strike_fired = true
			var damage := 8 if not is_player else character.heavy_damage if attack_kind == &"heavy" else character.finisher_damage if combo == 3 else character.damage
			var reach := character.heavy_reach if is_player and attack_kind == &"heavy" else character.reach + (20.0 if attack_kind == &"dash" else 0.0) if is_player else 105.0
			var launch := character.launch if attack_kind == &"heavy" else 130.0 if combo == 3 else 0.0
			strike.emit(self, damage, reach, launch)
		if attack_kind == &"dash":
			velocity.x = facing * 340.0
		if attack_elapsed >= attack_duration:
			attack_kind = &""
	velocity += knockback
	knockback = knockback.move_toward(Vector2.ZERO, 1050.0 * delta)
	move_and_slide()
	position.x = clampf(position.x, FLOOR_BOUNDS.position.x, FLOOR_BOUNDS.end.x)
	position.y = clampf(position.y, FLOOR_BOUNDS.position.y, FLOOR_BOUNDS.end.y)
	queue_redraw()

func _player_input() -> void:
	if Input.is_action_just_pressed(&"attack"):
		attack_buffer = 0.12
	if Input.is_action_just_pressed(&"heavy"):
		heavy_buffer = 0.12
	if stun > 0:
		return
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var horizontal := Input.get_axis(&"move_left", &"move_right")
	if Input.is_action_just_pressed(&"move_left") or Input.is_action_just_pressed(&"move_right"):
		var now := Time.get_ticks_msec() / 1000.0
		running = horizontal != 0 and horizontal == last_direction and now - last_tap <= 0.26
		last_tap = now
		last_direction = horizontal
	if horizontal == 0:
		running = false
	if attack_kind == &"":
		if horizontal != 0:
			facing = signf(horizontal)
		var speed := 385.0 if running else 255.0
		velocity = Vector2(direction.x * speed, direction.y * speed * 0.65)
		if Input.is_action_just_pressed(&"jump") and jump_height == 0:
			jump_velocity = 460.0
			jump_height = 1.0
		if Input.is_action_just_pressed(&"dash") and dash_cooldown == 0:
			dash_remaining = 0.17
			dash_cooldown = 0.7
			invulnerability = maxf(invulnerability, 0.22)
		if heavy_buffer > 0 and heavy_cooldown == 0 and jump_height == 0:
			heavy_buffer = 0
			heavy_cooldown = character.heavy_cooldown
			begin_attack(&"heavy", character.heavy_duration, character.heavy_duration / 3.0)
		elif attack_buffer > 0 or Input.is_action_pressed(&"attack"):
			attack_buffer = 0
			combo = combo % 3 + 1 if combo_timeout > 0 else 1
			combo_timeout = 0.65
			var kind: StringName = &"air" if jump_height > 0 else &"dash" if dash_remaining > 0 or running else &"basic"
			begin_attack(kind, character.attack_duration, character.attack_duration / 3.0)

func _enemy_input() -> void:
	if not is_instance_valid(target) or target.health <= 0 or stun > 0 or jump_height > 0 or attack_kind != &"":
		return
	var difference := target.position - position
	facing = 1.0 if difference.x >= 0 else -1.0
	if absf(difference.x) < 90 and absf(difference.y) < 30 and ai_cooldown == 0:
		ai_cooldown = 1.6
		begin_attack(&"goblin", 0.85, 0.6)
	else:
		velocity.x = signf(difference.x) * 85.0 if absf(difference.x) > 65 else 0.0
		velocity.y = signf(difference.y) * 60.0 if absf(difference.y) > 8 else 0.0

func begin_attack(kind: StringName, duration: float, impact: float) -> void:
	attack_kind = kind
	attack_elapsed = 0
	attack_duration = duration
	strike_time = impact
	strike_fired = false

func take_hit(damage: int, direction: float, launch: float) -> bool:
	if health <= 0 or invulnerability > 0:
		return false
	if not immortal:
		health = maxi(0, health - damage)
	flash = 0.12
	stun = 0.2
	knockback = Vector2(direction * 245.0, 0)
	if launch > 0:
		jump_height = maxf(1, jump_height)
		jump_velocity = launch
	attack_kind = &""
	dash_remaining = 0
	if is_player:
		invulnerability = 0.65
	hurt.emit(damage)
	if health == 0:
		defeated.emit()
	return true

func clear_buffer() -> void:
	attack_buffer = 0
	heavy_buffer = 0
	running = false
	last_tap = -10

func _draw() -> void:
	draw_ellipse_shadow()
	var feet := Vector2(0, -jump_height)
	var color := character.tint if is_player else Color(0.43, 0.75, 0.35)
	if flash > 0:
		color = Color.WHITE
	if is_player and invulnerability > 0 and int(Time.get_ticks_msec() / 70) % 2 == 0:
		color.a = 0.5
	var body_height := 54.0 if is_player else 36.0
	draw_line(feet + Vector2(-8, -4), feet + Vector2(-5, -22), color, 6)
	draw_line(feet + Vector2(8, -4), feet + Vector2(5, -22), color, 6)
	draw_rect(Rect2(feet + Vector2(-13, -body_height), Vector2(26, body_height - 19)), color)
	draw_circle(feet + Vector2(0, -body_height - 10), 12, color)
	if not is_player:
		draw_colored_polygon(PackedVector2Array([feet + Vector2(-9, -50), feet + Vector2(-26, -53), feet + Vector2(-11, -37)]), color)
		draw_colored_polygon(PackedVector2Array([feet + Vector2(9, -50), feet + Vector2(26, -53), feet + Vector2(11, -37)]), color)
	draw_circle(feet + Vector2(facing * 5, -body_height - 12), 2, Color.BLACK)
	var hand := feet + Vector2(facing * 13, -body_height + 14)
	var weapon_end := hand + Vector2(facing * (45 if is_player else 28), -12)
	if attack_kind != &"":
		var progress := clampf(attack_elapsed / attack_duration, 0, 1)
		var angle := lerpf(-1.5, 1.2, progress)
		weapon_end = hand + Vector2(facing * cos(angle) * 65, sin(angle) * 65)
		if strike_fired and is_player and character.projectile_speed == 0:
			draw_arc(hand, 75, -1.2 if facing > 0 else PI - 1.2, 1.2 if facing > 0 else PI + 1.2, 16, Color(1, 0.85, 0.35, 0.7), 4)
		if strike_fired and is_player and attack_kind == &"heavy" and character.radial_heavy:
			draw_arc(feet + Vector2(0, -25), character.heavy_reach, 0, TAU, 40, character.tint, 4)
		if not is_player and not strike_fired:
			draw_arc(feet + Vector2(0, -24), 48, 0, TAU, 24, Color(1, 0.3, 0.25), 3)
	if is_player and character.weapon == "gun":
		weapon_end = hand + Vector2(facing * 37, 0)
		draw_line(hand, weapon_end, Color.GRAY, 9)
		draw_line(hand, hand + Vector2(0, 13), Color.GRAY, 6)
	elif is_player and character.weapon == "fists":
		draw_circle(hand + Vector2(facing * (35 if attack_kind != &"" else 7), 0), 11, character.tint.lightened(0.3))
	elif is_player and character.weapon == "staff":
		weapon_end = hand + Vector2(facing * 24, -45)
		draw_line(hand + Vector2(-facing * 10, 25), weapon_end, Color.SADDLE_BROWN, 6)
		draw_circle(weapon_end, 10, character.tint.lightened(0.3))
	else:
		if is_player and character.weapon == "cross":
			var axis := (weapon_end - hand).normalized()
			var perpendicular := Vector2(-axis.y, axis.x) * 19
			draw_line(weapon_end - axis * 18 - perpendicular, weapon_end - axis * 18 + perpendicular, Color.GOLDENROD, 10)
		draw_line(hand, weapon_end, Color(0.85, 0.87, 0.9) if is_player else Color(0.65, 0.43, 0.25), 5)
	draw_string(ThemeDB.fallback_font, feet + Vector2(-22, -body_height - 34), character.display_name.to_upper() if is_player else "GOBLIN ∞", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 23, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO)
