extends SceneTree
const Main := preload("res://scenes/main.tscn")
var passed := 0
var failed := 0

func check(value: bool, message: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		push_error(message)

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app := Main.instantiate()
	root.add_child(app)
	await frames(2)
	app.find_child("StartButton", true, false).pressed.emit()
	app.find_child("SlayerButton", true, false).pressed.emit()
	app.dungeon_index = -1
	app.find_child("EnterButton", true, false).pressed.emit()
	await frames(2)
	var player: DemoFighter = app.arena.player
	app.arena.goblin.ai_enabled = false
	app.arena.goblin.position = Vector2(1100, 590)
	Input.action_press("attack")
	await frames(3)
	check(player.combo == 1 and is_equal_approx(player.attack_duration, 0.6), "First attack retains its 600ms source sequence")
	check(is_equal_approx(player.strike_time, 0.15), "First attack impact begins at source 150ms")
	await frames(36)
	check(player.combo == 2 and is_equal_approx(player.attack_duration, 0.65), "Held X advances to 650ms second stage")
	check(is_equal_approx(player.strike_time, 0.1), "Second stage impact begins at source 100ms")
	await frames(39)
	check(player.combo == 3 and is_equal_approx(player.attack_duration, 0.55), "Combo timeout allows the 550ms third stage")
	await frames(25)
	Input.action_release("attack")
	await frames(15)
	check(player.attack_kind == &"", "Combo returns to idle after recovery")
	Input.action_press("move_right")
	await frames(2)
	Input.action_release("move_right")
	await frames(2)
	Input.action_press("move_right")
	await frames(3)
	check(player.running, "Double-tap input starts running")
	Input.action_press("attack")
	await frames(3)
	Input.action_release("attack")
	Input.action_release("move_right")
	var start_x := player.position.x
	check(player.attack_kind == &"dash", "Running plus X dispatches contextual running attack")
	check(player.art.slayer_visual.action == "dashattack", "Running attack selects thrust instead of generic fallback")
	check(is_equal_approx(player.attack_duration, 0.63) and is_equal_approx(player.strike_time, 0.18), "Running attack retains 630ms duration and 180ms strike")
	await frames(5)
	check(not player.strike_fired, "Running thrust does not hit before its windup finishes")
	await frames(5)
	check(player.strike_fired, "Running thrust fires its existing damage event")
	await frames(30)
	check(player.attack_kind == &"", "Running attack returns to idle after recovery")
	check(player.position.x - start_x > 40 and player.position.x - start_x < 120, "Longer recovery preserves the short lunge distance")
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/slayer/animation-proof/animations.json"))
	for stage in range(1, 4):
		var clip: Dictionary = source["clips"]["attack%d_right" % stage]
		var total := 0.0
		var impact := 0.0
		for index in range(clip["durations"].size()):
			total += float(clip["durations"][index])
			if index < int(clip["impact_frame"]):
				impact += float(clip["durations"][index])
		var timing: Vector2 = player.character.attack_timing(&"basic", stage)
		check(is_equal_approx(timing.x, total) and is_equal_approx(timing.y, impact), "Combat and source animation clocks agree for each stage")
	for definition: DemoCharacter in app.CHARACTERS:
		if definition.weapon == "sword":
			continue
		var timing := definition.attack_timing(&"basic", 2)
		check(is_equal_approx(timing.x, definition.attack_duration) and is_equal_approx(timing.y, definition.attack_duration / 3), "Other characters retain their existing combat timing")
	app.queue_free()
	await frames(2)
	print("SLAYER MOTIONS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
