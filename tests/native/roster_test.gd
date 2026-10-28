extends SceneTree

const Main := preload("res://scenes/main.tscn")
const IDS: Array[String] = ["Slayer", "Gunner", "Fighter", "Mage", "Priest"]
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

func frames(count: int) -> void:
	for frame in range(count):
		await physics_frame

func press(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)

func reset_target(arena: DemoArena, offset: Vector2) -> void:
	arena.player.position = Vector2(400, 430)
	arena.player.facing = 1
	arena.goblin.position = arena.player.position + offset
	arena.goblin.jump_height = 0
	arena.goblin.jump_velocity = 0
	arena.goblin.knockback = Vector2.ZERO

func run() -> void:
	var app := Main.instantiate()
	root.add_child(app)
	await process_frame
	for id in IDS:
		app.show_selection()
		await process_frame
		var card: Button = app.find_child(id + "Button", true, false)
		check(card != null, id + " is selectable")
		if card == null:
			continue
		card.button_pressed = true
		card.pressed.emit()
		app.dungeon_index = -1
		app.find_child("EnterButton", true, false).pressed.emit()
		await physics_frame
		var definition: Resource = app.arena.get("character")
		check(definition != null, id + " reaches arena with class data")
		var arena: DemoArena = app.arena
		arena.goblin.ai_enabled = false
		check(arena.player.character.display_name == id, id + " has matching player data")
		check(app.health_label.text.begins_with(id), id + " appears in HUD")
		reset_target(arena, Vector2(60, 0))
		await press("attack")
		await frames(40)
		check(arena.hits == 1, id + " basic input lands one hit")
		reset_target(arena, Vector2(60, 0))
		var before := arena.hits
		await press("heavy")
		await frames(45)
		check(arena.hits == before + 1, id + " class skill hits")
		check(arena.total_damage >= arena.character.damage + arena.character.heavy_damage, id + " uses class damage")
		await frames(70)
		reset_target(arena, Vector2(300, 0))
		before = arena.hits
		await press("attack")
		await frames(70)
		check((arena.hits > before) == (arena.character.projectile_speed > 0), id + " has correct ranged/melee reach")
		reset_target(arena, Vector2(60, 100))
		before = arena.hits
		await press("attack")
		await frames(100)
		check(arena.hits == before, id + " misses other lanes")
		reset_target(arena, Vector2(-60, 0))
		before = arena.hits
		await press("heavy")
		await frames(70)
		check((arena.hits > before) == arena.character.radial_heavy, id + " skill respects facing or radial range")
		check(arena.goblin.health == 100, id + " cannot kill goblin")
		if arena.character.projectile_speed > 0:
			reset_target(arena, Vector2(500, 0))
			await press("attack")
			await frames(8)
			var shots := get_nodes_in_group("player_projectiles")
			check(not shots.is_empty(), id + " creates visible projectile")
			if not shots.is_empty():
				var shot: Node2D = shots[0]
				var at := shot.position
				app.pause_game()
				await frames(10)
				check(shot.position == at, id + " projectiles freeze on pause")
				app.resume_game()
		app.start_dungeon()
		await frames(2)
		check(app.arena.character.display_name == id and app.arena.hits == 0, id + " restart preserves class and clears score")
		check(get_nodes_in_group("player_projectiles").is_empty(), id + " restart clears projectiles")
	app.queue_free()
	await process_frame
	print("DFA roster: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
