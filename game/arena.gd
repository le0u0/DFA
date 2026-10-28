extends Node2D
class_name DemoArena

signal stats_changed(health: int, hits: int, damage: int)
signal player_defeated
const Fighter := preload("res://game/fighter.gd")
const Projectile := preload("res://game/projectile.gd")
@export var character: DemoCharacter = preload("res://game/characters/slayer.tres")
var player: DemoFighter
var goblin: DemoFighter
var hits := 0
var total_damage := 0
var popups: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	y_sort_enabled = true
	player = Fighter.new()
	player.name = "Player"
	player.is_player = true
	player.character = character
	player.position = Vector2(400, 430)
	add_child(player)
	goblin = Fighter.new()
	goblin.name = "ImmortalGoblin"
	goblin.immortal = true
	goblin.position = Vector2(780, 430)
	goblin.target = player
	add_child(goblin)
	player.strike.connect(_on_strike)
	goblin.strike.connect(_on_strike)
	player.hurt.connect(func(_damage: int) -> void: _update_stats())
	player.defeated.connect(func() -> void: player_defeated.emit())
	_update_stats()

func _physics_process(delta: float) -> void:
	for popup in popups:
		popup["life"] = float(popup["life"]) - delta
	popups = popups.filter(func(p: Dictionary) -> bool: return float(p["life"]) > 0)
	queue_redraw()

func _on_strike(attacker: DemoFighter, damage: int, reach: float, launch: float) -> void:
	var victim := goblin if attacker == player else player
	var radial := attacker == player and attacker.attack_kind == &"heavy" and character.radial_heavy
	if attacker == player and character.projectile_speed > 0 and not radial:
		var shot := Projectile.new()
		shot.name = "Projectile"
		shot.add_to_group("player_projectiles")
		shot.position = attacker.position + Vector2(attacker.facing * 18, 0)
		shot.height = attacker.jump_height + 40
		shot.direction = attacker.facing
		shot.speed = character.projectile_speed
		shot.remaining = reach
		shot.damage = damage
		shot.launch = launch
		shot.tint = character.tint
		shot.victim = victim
		# Aim at a short target's body only when it occupies the firing lane.
		var distance := (victim.position.x - shot.position.x) * shot.direction
		if distance > 0 and absf(victim.position.y - shot.position.y) <= 34:
			shot.vertical_speed = (victim.jump_height + 25 - shot.height) * shot.speed / maxf(40, distance)
		shot.hit.connect(func(amount: int, direction: float, lift: float) -> void: _record_hit(victim, amount, direction, lift, true))
		add_child(shot)
		return
	var offset := victim.position - attacker.position
	var height_range := 125.0 if attacker.attack_kind == &"air" else 90.0
	var horizontal_hit := absf(offset.x) <= reach if radial else offset.x * attacker.facing >= -12 and offset.x * attacker.facing <= reach
	if not horizontal_hit or absf(offset.y) > 34 or absf(victim.jump_height - attacker.jump_height) > height_range:
		return
	_record_hit(victim, damage, attacker.facing, launch, attacker == player)

func _record_hit(victim: DemoFighter, damage: int, direction: float, launch: float, from_player: bool) -> void:
	if not victim.take_hit(damage, direction, launch):
		return
	if from_player:
		hits += 1
		total_damage += damage
	popups.append({"position": victim.position - Vector2(0, victim.jump_height + 75), "damage": damage, "life": 0.65, "player": victim == player})
	_update_stats()

func _update_stats() -> void:
	stats_changed.emit(player.health, hits, total_damage)

func clear_input() -> void:
	player.clear_buffer()

func _draw() -> void:
	draw_rect(Rect2(55, 205, 1170, 450), Color(0.18, 0.19, 0.21))
	draw_rect(Rect2(55, 205, 1170, 450), Color(0.45, 0.47, 0.50), false, 2)
	for x in range(80, 1220, 80):
		draw_line(Vector2(x, 210), Vector2(x, 650), Color(0.24, 0.25, 0.27), 1)
	for y in range(235, 650, 50):
		draw_line(Vector2(60, y), Vector2(1220, y), Color(0.24, 0.25, 0.27), 1)
	for popup in popups:
		var at: Vector2 = popup["position"]
		at.y -= (0.65 - float(popup["life"])) * 45.0
		var color := Color(1, 0.4, 0.35) if popup["player"] else Color(1, 0.9, 0.45)
		color.a = minf(1, float(popup["life"]) * 5)
		draw_string(ThemeDB.fallback_font, at, str(popup["damage"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 25, color)
