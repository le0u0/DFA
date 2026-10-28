extends SceneTree

const Main := preload("res://scenes/main.tscn")
var passed := 0
var failed := 0

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func tick(count := 2) -> void:
	for index in range(count):
		await physics_frame

func quiet(arena: DemoArena) -> void:
	for enemy in arena.enemies:
		enemy.ai_enabled = false

func kill_room(arena: DemoArena) -> void:
	for enemy in arena.enemies:
		enemy.invulnerability = 0
		enemy.take_hit(9999, 1, 0)

func scenarios() -> bool:
	var app := Main.instantiate()
	root.add_child(app)
	await tick()
	app.show_selection()
	app.find_child("SlayerButton", true, false).pressed.emit()
	var choice: OptionButton = app.find_child("DungeonChoice", true, false)
	check(choice.item_count == 3, "two dungeons and training available")
	choice.select(1)
	choice.item_selected.emit(1)
	app.find_child("EnterButton", true, false).pressed.emit()
	await tick()
	check(app.arena.dungeon_index == 1, "selection enters second dungeon directly")
	app.arena.player.take_hit(999, 1, 0)
	check(paused, "dungeon defeat pauses combat")
	app.find_child("RestartButton", true, false).pressed.emit()
	await tick()
	check(app.arena.dungeon_index == 1 and app.arena.room_index == 0 and app.arena.player.health == 100, "retry preserves dungeon and resets run")
	for definition: DemoCharacter in app.CHARACTERS:
		for dungeon in range(2):
			app.selected_character = definition
			app.dungeon_index = dungeon
			app.start_dungeon()
			await tick()
			var arena: DemoArena = app.arena
			for room in range(3):
				quiet(arena)
				check(arena.room_index == room and not arena.cleared, "room starts active")
				arena.advance_room()
				check(arena.room_index == room, "living enemies lock exit")
				var enemy := arena.enemies[0]
				check(not enemy.immortal, "dungeon enemies are mortal")
				if room > 0:
					check(enemy.enemy_data["rank"] == ("elite" if room == 1 else "boss"), "each dungeon has elite and boss")
				arena.player.position = Vector2(400, 430)
				arena.player.facing = 1
				enemy.position = Vector2(460, 430)
				var before := enemy.health
				arena.player.begin_attack(&"basic", definition.attack_duration, definition.attack_duration / 3)
				await tick(45)
				check(enemy.health < before and arena.hits > 0, definition.display_name + " damages dungeon monster")
				if room == 2:
					enemy.stun = 0
					enemy.jump_height = 0
					enemy.position = Vector2(460, 430)
					enemy.facing = -1
					enemy.begin_attack(StringName(enemy.enemy_data["special"]), 1.5, 1.0)
					arena.player.invulnerability = 0
					var hp := arena.player.health
					arena._on_strike(enemy, 10, enemy.enemy_reach(), 0)
					check(arena.player.health == hp - 10, "boss special hits its warned lane")
					arena.player.invulnerability = 0
					arena.player.position.y += 100
					arena._on_strike(enemy, 10, enemy.enemy_reach(), 0)
					check(arena.player.health == hp - 10, "leaving warning lane avoids special")
					arena.player.position.y -= 100
					arena.player.jump_height = 40
					if dungeon == 0:
						arena._on_strike(enemy, 10, enemy.enemy_reach(), 0)
						check(arena.player.health == hp - 10, "jump avoids Root King stomp")
					arena.player.jump_height = 0
				if arena.enemies.size() > 1:
					enemy.take_hit(9999, 1, 0)
					check(not arena.cleared and not paused, "partial defeat does not unlock room")
				arena.player.health = 50
				kill_room(arena)
				check(arena.cleared and paused, "all defeated opens clear panel and stops combat")
				check(not enemy.visible and enemy.collision_layer == 0, "dead enemy cannot block player")
				app.resume_game()
				check(paused, "Esc cannot bypass clear gate")
				if room < 2:
					app.find_child("NextRoomButton", true, false).pressed.emit()
					await tick()
					check(not paused and arena.player.health == 75, "next room restores 25 health and resumes")
					check(get_nodes_in_group("player_projectiles").is_empty(), "room transition clears projectiles")
				else:
					check(app.find_child("NextDungeonButton" if dungeon == 0 else "ReplayButton", true, false) != null, "boss clear offers next dungeon or replay")
					if dungeon == 0:
						app.find_child("NextDungeonButton", true, false).pressed.emit()
						await tick()
						check(app.arena.dungeon_index == 1 and not paused, "next dungeon starts fresh")
	# A projectile must hit the first crossed enemy, even if the roster is reversed.
	app.dungeon_index = 0
	app.selected_character = app.CHARACTERS[1]
	app.start_dungeon()
	await tick()
	var ranged: DemoArena = app.arena
	quiet(ranged)
	ranged.player.position = Vector2(300, 430)
	ranged.enemies[0].position = Vector2(600, 430)
	ranged.enemies[1].position = Vector2(450, 430)
	ranged._on_strike(ranged.player, 10, 700, 0)
	await tick(25)
	check(ranged.enemies[0].health == 45 and ranged.enemies[1].health == 35, "projectile strikes nearest crossed enemy")
	ranged.enemies[1].take_hit(999, 1, 0)
	ranged._on_strike(ranged.player, 10, 700, 0)
	await tick(30)
	check(ranged.enemies[0].health == 35, "dead frontline enemy does not absorb projectiles")
	app.selected_character = app.CHARACTERS[0]
	app.start_dungeon()
	await tick()
	var melee: DemoArena = app.arena
	quiet(melee)
	melee.player.position = Vector2(400, 430)
	melee.enemies[0].position = Vector2(460, 420)
	melee.enemies[1].position = Vector2(490, 440)
	melee._on_strike(melee.player, 10, 120, 0)
	check(melee.enemies[0].health == 35 and melee.enemies[1].health == 35, "melee strikes multiple enemies in its area")
	var enemy := melee.enemies[0]
	enemy.enemy_data = melee.Dungeons.ENEMIES["root_king"]
	enemy.stun = 0
	enemy.ai_cooldown = 0
	enemy.enemy_attack_count = 1
	enemy._enemy_input()
	check(enemy.attack_kind == &"stomp" and enemy.strike_time > 1.0, "boss AI alternates into telegraphed special")
	app.show_main()
	await tick()
	check(app.arena == null and not paused, "return to menu cleans dungeon and unpauses")
	app.queue_free()
	await tick()
	return true

func run() -> void:
	if await scenarios() != true:
		failed += 1
	print("DFA dungeons: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
