extends Node2D
class_name DemoArena

signal stats_changed(health: int, hits: int, damage: int)
signal player_defeated
signal room_cleared
const Dungeons := preload("res://game/dungeons.gd")
var dungeon_index := -1
var room_index := 0
var enemies: Array[DemoFighter] = []
var cleared := false
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
	player.strike.connect(_on_strike)
	_spawn_room()
	player.hurt.connect(func(_damage: int) -> void: _update_stats())
	player.defeated.connect(func() -> void: player_defeated.emit())
	_update_stats()

func _physics_process(delta: float) -> void:
	for popup in popups:
		popup["life"] = float(popup["life"]) - delta
	popups = popups.filter(func(p: Dictionary) -> bool: return float(p["life"]) > 0)
	queue_redraw()

func _spawn_room() -> void:
	cleared = false
	player.position = Vector2(400 if dungeon_index < 0 else 300, 430)
	var roster: Array = ["training"] if dungeon_index < 0 else Dungeons.LIST[dungeon_index]["rooms"][room_index]["enemies"]
	for index in range(roster.size()):
		var enemy := Fighter.new()
		enemy.name = "Enemy%d" % index
		enemy.immortal = dungeon_index < 0
		if not enemy.immortal:
			enemy.enemy_data = Dungeons.ENEMIES[roster[index]]
		enemy.position = Vector2(780, 430) if dungeon_index < 0 else Vector2(760 + index * 135, 390 + index * 60)
		enemy.target = player
		enemy.ai_cooldown += index * 0.35
		add_child(enemy)
		enemies.append(enemy)
		enemy.strike.connect(_on_strike)
		enemy.defeated.connect(_on_enemy_defeated)
	goblin = enemies[0]

func _on_enemy_defeated() -> void:
	if cleared or player.health <= 0:
		return
	for enemy in enemies:
		if enemy.health > 0:
			return
	cleared = true
	clear_input()
	room_cleared.emit()

func advance_room() -> void:
	if not cleared or room_index >= 2 or player.health <= 0:
		return
	for child in get_children():
		if child is DemoFighter and child != player or child.get_script() == Projectile:
			remove_child(child)
			child.queue_free()
	enemies.clear()
	popups.clear()
	room_index += 1
	player.health = mini(100, player.health + 25)
	player.attack_kind = &""
	player.jump_height = 0
	player.jump_velocity = 0
	player.knockback = Vector2.ZERO
	player.dash_remaining = 0
	player.invulnerability = 0.8
	_spawn_room()
	_update_stats()

func room_title() -> String:
	if dungeon_index < 0:
		return "Training chamber · Immortal goblin"
	return "%s · Room %d/3 · %s" % [Dungeons.LIST[dungeon_index]["name"], room_index + 1, Dungeons.LIST[dungeon_index]["rooms"][room_index]["name"]]

func _on_strike(attacker: DemoFighter, damage: int, reach: float, launch: float) -> void:
	if cleared or attacker.health <= 0 or player.health <= 0:
		return
	var victims: Array[DemoFighter] = []
	if attacker == player:
		victims.assign(enemies)
	else:
		victims.append(player)
	var radial := attacker.attack_kind == &"stomp" or (attacker == player and attacker.attack_kind == &"heavy" and character.radial_heavy)
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
		shot.victims.assign(enemies)
		# Aim at the nearest live enemy in the firing lane.
		var distance := INF
		for victim in enemies:
			var ahead := (victim.position.x - shot.position.x) * shot.direction
			if victim.health > 0 and ahead > 0 and ahead < distance and absf(victim.position.y - shot.position.y) <= 34:
				distance = ahead
				shot.vertical_speed = (victim.jump_height + 25 - shot.height) * shot.speed / maxf(40, distance)
		shot.hit_target.connect(func(victim: DemoFighter, amount: int, direction: float, lift: float) -> void: _record_hit(victim, amount, direction, lift, true))
		add_child(shot)
		return
	for victim in victims:
		var offset := victim.position - attacker.position
		var height_range := 125.0 if attacker.attack_kind == &"air" else 90.0
		if attacker.attack_kind == &"stomp":
			height_range = 18.0
		var horizontal_hit := absf(offset.x) <= reach if radial else offset.x * attacker.facing >= -12 and offset.x * attacker.facing <= reach
		if horizontal_hit and absf(offset.y) <= 34 and absf(victim.jump_height - attacker.jump_height) <= height_range:
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
	var floor_color := Color(0.18, 0.19, 0.21) if dungeon_index < 0 else Color(Dungeons.LIST[dungeon_index]["floor"])
	var accent := Color(0.45, 0.47, 0.50) if dungeon_index < 0 else Color(Dungeons.LIST[dungeon_index]["accent"])
	draw_rect(Rect2(55, 205, 1170, 450), floor_color)
	draw_rect(Rect2(55, 205, 1170, 450), accent, false, 2)
	for x in range(80, 1220, 80):
		draw_line(Vector2(x, 210), Vector2(x, 650), floor_color.lightened(0.08), 1)
	for y in range(235, 650, 50):
		draw_line(Vector2(60, y), Vector2(1220, y), floor_color.lightened(0.08), 1)
	if dungeon_index >= 0:
		for x in [100, 350, 930, 1180]:
			if dungeon_index == 0:
				draw_rect(Rect2(x - 12, 155, 24, 55), Color("574735"))
				draw_circle(Vector2(x, 140), 42, accent.darkened(0.25))
			else:
				draw_rect(Rect2(x - 22, 110, 44, 100), accent.darkened(0.45))
				draw_line(Vector2(x - 12, 180), Vector2(x + 12, 130), accent, 3)
	for popup in popups:
		var at: Vector2 = popup["position"]
		at.y -= (0.65 - float(popup["life"])) * 45.0
		var color := Color(1, 0.4, 0.35) if popup["player"] else Color(1, 0.9, 0.45)
		color.a = minf(1, float(popup["life"]) * 5)
		draw_string(ThemeDB.fallback_font, at, str(popup["damage"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 25, color)
