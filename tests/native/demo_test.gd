extends SceneTree

var passed := 0
var failed := 0
const Main := preload("res://scenes/main.tscn")

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app := Main.instantiate()
	root.add_child(app)
	await process_frame
	check(app.screen == "main", "opens on main menu")
	check(app.find_child("StartButton", true, false) != null, "main has Start")
	check(app.find_child("QuitButton", true, false) != null, "main has Quit")
	app.find_child("StartButton", true, false).pressed.emit()
	await process_frame
	check(app.screen == "selection", "Start opens character selection")
	check(app.find_child("EnterButton", true, false).disabled, "selection required before entering")
	var select: Button = app.find_child("SlayerButton", true, false)
	select.button_pressed = true
	select.pressed.emit()
	check(not app.find_child("EnterButton", true, false).disabled, "selecting Slayer enables dungeon")
	app.find_child("EnterButton", true, false).pressed.emit()
	await physics_frame
	check(app.screen == "arena", "enters dungeon")
	var arena: DemoArena = app.arena
	check(arena.player.is_player and arena.goblin.immortal, "one player and one immortal goblin")
	arena.goblin.ai_enabled = false
	var start_x := arena.player.position.x
	Input.action_press("move_right")
	for frame in range(20):
		await physics_frame
	Input.action_release("move_right")
	check(arena.player.position.x > start_x + 50, "real input moves fighter")
	arena.goblin.position = arena.player.position + Vector2(75, 0)
	Input.action_press("attack")
	for frame in range(16):
		await physics_frame
	Input.action_release("attack")
	check(arena.hits > 0 and arena.total_damage > 0, "attack hits goblin and updates totals")
	for hit in range(100):
		arena.goblin.take_hit(999, 1, 0)
	check(arena.goblin.health == 100, "goblin survives repeated lethal damage")
	arena.goblin.position = arena.player.position + Vector2(75, 90)
	var hits_before := arena.hits
	for frame in range(20):
		await physics_frame
	Input.action_press("attack")
	for frame in range(12):
		await physics_frame
	Input.action_release("attack")
	check(arena.hits == hits_before, "attacks do not cross ground lanes")
	for frame in range(20):
		await physics_frame
	Input.action_press("jump")
	await physics_frame
	await physics_frame
	Input.action_release("jump")
	check(arena.player.jump_height > 0, "C action jumps above ground plane")
	for frame in range(60):
		await physics_frame
	check(is_zero_approx(arena.player.jump_height), "jump lands")
	arena.goblin.position = arena.player.position + Vector2(75, 0)
	Input.action_press("heavy")
	await physics_frame
	await physics_frame
	Input.action_release("heavy")
	for frame in range(20):
		await physics_frame
	check(arena.goblin.jump_height > 0, "launcher sends immortal goblin airborne")
	for frame in range(70):
		await physics_frame
	arena.goblin.position = arena.player.position + Vector2(75, 0)
	arena.goblin.ai_enabled = true
	arena.goblin.ai_cooldown = 0
	var health_before := arena.player.health
	for frame in range(55):
		await physics_frame
	check(arena.player.health < health_before, "goblin telegraphs and strikes back")
	for frame in range(20):
		await physics_frame
	Input.action_press("dash")
	await physics_frame
	await physics_frame
	Input.action_release("dash")
	check(arena.player.invulnerability > 0, "dodge grants brief invulnerability")
	app.pause_game()
	var paused_position := arena.player.position
	Input.action_press("move_left")
	for frame in range(10):
		await physics_frame
	Input.action_release("move_left")
	check(arena.player.position == paused_position, "pause freezes arena physics")
	app.resume_game()
	check(not paused, "resume restores game")
	arena.player.invulnerability = 0
	arena.player.take_hit(999, -1, 0)
	check(paused and app.find_child("RestartButton", true, false) != null, "player defeat offers restart")
	app.find_child("RestartButton", true, false).pressed.emit()
	await physics_frame
	check(app.arena.player.health == 100 and app.arena.hits == 0, "restart resets arena")
	app.show_main()
	await process_frame
	check(app.arena == null and app.screen == "main", "main menu frees arena")
	app.queue_free()
	await process_frame
	print("DFA native demo: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
