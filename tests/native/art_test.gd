extends SceneTree

const Main := preload("res://scenes/main.tscn")
var failed := 0
var passed := 0

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func tick(count := 2) -> void:
	for index in range(count):
		await physics_frame

func run() -> void:
	var app := Main.instantiate()
	root.add_child(app)
	await tick()
	app.find_child("ArtDemoButton", true, false).pressed.emit()
	await tick()
	var player: DemoFighter = app.arena.player
	app.arena.goblin.ai_enabled = false
	var visual: Node2D = player.art
	check(visual != null, "Art demo installs Slayer renderer")
	check(visual.body.get_size() == Vector2(512, 768), "Body atlas has 24 fixed cells")
	check(visual.row == 3, "Right idle uses authored right-facing row")
	player.facing = -1
	await tick()
	check(visual.row == 0, "Left idle uses authored left-facing row")
	Input.action_press("move_left")
	await tick(4)
	check(visual.row == 1, "Movement selects walk strip")
	Input.action_release("move_left")
	await tick()
	var original_damage := player.character.damage
	Input.action_press("swap_weapon")
	await tick()
	Input.action_release("swap_weapon")
	check(visual.weapon_index == 1, "V input swaps to second independent sword")
	check(player.character.damage == original_damage, "Art swap preserves combat tuning")
	player.begin_attack(&"basic", 0.6, 0.2)
	await tick()
	check(visual.row == 2 and visual.frame == 0, "Attack starts with anticipation")
	await tick(14)
	check(visual.frame == 1, "Impact pose follows existing strike timing")
	app.pause_game()
	var previous_clock: float = visual.clock
	var previous_frame: int = visual.frame
	await tick(8)
	check(visual.clock == previous_clock and visual.frame == previous_frame, "Animation freezes on pause")
	app.resume_game()
	await tick(35)
	Input.action_press("swap_weapon")
	await tick()
	Input.action_release("swap_weapon")
	check(visual.weapon_index == 0, "Sword selection cycles back")
	player.health = 0
	await tick(10)
	check(visual.row == 0 and visual.frame == 3, "Defeated player holds a still pose")
	for definition: DemoCharacter in app.CHARACTERS:
		app.selected_character = definition
		app.selected = true
		app.start_dungeon()
		await tick()
		app.arena.goblin.ai_enabled = false
		player = app.arena.player
		visual = player.art
		var prefix := definition.display_name + ": "
		check(visual != null and visual.weapon_kind == definition.weapon, prefix + "class renderer selected")
		check(visual.body.get_size() == Vector2(512, 768), prefix + "24-frame atlas available")
		check(visual.equipment.size() == 2, prefix + "two independent equipment sprites")
		player.facing = -1
		Input.action_press("move_left")
		await tick()
		check(visual.row == 1, prefix + "left walk")
		Input.action_release("move_left")
		player.begin_attack(&"basic", 0.6, 0.2)
		await tick(15)
		check(visual.row == 2 and visual.frame == 1, prefix + "left attack impact")
		await tick(30)
		player.facing = 1
		player.begin_attack(&"heavy", 0.6, 0.2)
		await tick(15)
		check(visual.row == 5 and visual.frame == 1, prefix + "right skill impact")
		var before_damage: int = player.character.damage
		var before_reach: float = player.character.reach
		Input.action_press("swap_weapon")
		await tick()
		Input.action_release("swap_weapon")
		check(visual.weapon_index == 1, prefix + "equipment swap input")
		check(player.character.damage == before_damage and player.character.reach == before_reach, prefix + "swap preserves combat")
		app.pause_game()
		previous_clock = visual.clock
		await tick(4)
		check(visual.clock == previous_clock, prefix + "pause freezes animation")
		app.resume_game()
	app.queue_free()
	await tick()
	print("ART CHECKS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
