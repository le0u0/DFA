extends SceneTree

const Main := preload("res://scenes/main.tscn")
var passed := 0
var failed := 0

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func tick() -> void:
	await process_frame
	await process_frame

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await tick()
	event = InputEventKey.new()
	event.physical_keycode = code
	Input.parse_input_event(event)
	await tick()

func run() -> void:
	var app := Main.instantiate()
	root.add_child(app)
	await tick()
	var entry: Button = app.find_child("AnimationLabButton", true, false)
	check(entry != null, "Main menu exposes animation lab")
	entry.pressed.emit()
	await tick()
	var lab = app.find_child("SlayerAnimationLab", true, false)
	check(app.screen == "animation_lab" and app.arena == null, "Lab is isolated from combat")
	check(lab.large.data["clips"].size() == 6, "Six clips available")
	check(lab.large.ATLAS.get_size() == Vector2(768, 768), "Registered 36-cell atlas imported")
	lab.find_child("PlayButton", true, false).pressed.emit()
	var still: int = lab.large.frame
	var elapsed: float = lab.large.elapsed
	for index in range(5):
		await tick()
	check(lab.large.frame == still and lab.large.elapsed == elapsed, "Pause freezes playback")
	await key(KEY_2)
	check(lab.large.action == "walk" and lab.native.action == "walk", "Keyboard selects walk on both scales")
	lab.find_child("NextFrameButton", true, false).pressed.emit()
	check(not lab.playing and lab.large.frame == 1 and lab.native.frame == 1, "Frame step pauses and synchronizes views")
	lab.find_child("PreviousFrameButton", true, false).pressed.emit()
	lab.find_child("PreviousFrameButton", true, false).pressed.emit()
	check(lab.large.frame == 5, "Reverse stepping wraps to final frame")
	await key(KEY_F)
	check(lab.large.facing == "left" and lab.native.facing == "left", "Facing switches both authored views")
	check(lab.large.clip()["row"] == 1, "Left walk selects its independent source row")
	await key(KEY_F)
	check(lab.large.clip()["row"] == 4 and lab.large.scale.x > 0, "Right walk uses separate art without mirroring")
	lab.find_child("SwordButton", true, false).pressed.emit()
	check(lab.large.weapon_index == 1 and lab.native.weapon_index == 1, "Independent cyan sword selectable")
	await key(KEY_V)
	check(lab.large.weapon_index == 2, "Body-only review is available")
	await key(KEY_V)
	check(lab.large.weapon_index == 0, "Sword selector returns to steel")
	lab.find_child("SpeedChoice", true, false).item_selected.emit(0)
	check(lab.speed == 0.25, "Quarter-speed playback selectable")
	lab.find_child("AnchorsButton", true, false).button_pressed = true
	check(lab.large.show_anchors and lab.native.show_anchors, "Grip/foot markers are synchronized")
	await key(KEY_3)
	lab.find_child("LoopAttackButton", true, false).button_pressed = false
	check(lab.large.action == "attack" and not lab.large.repeat_attack, "Attack can be reviewed once")
	lab.large.advance(0.201)
	check(lab.large.frame == 2 and lab.large.clip()["impact_frame"] == 2, "Impact pose starts at one third of 0.6-second attack")
	lab.large.advance(1.0)
	check(lab.large.finished and lab.large.frame == 5, "Non-looping attack holds recovery")
	lab.large.advance(1.0)
	check(lab.large.frame == 5, "Completed attack does not advance")
	lab.find_child("LoopAttackButton", true, false).button_pressed = true
	lab.large.advance(0.61)
	check(not lab.large.finished and lab.large.frame == 0, "Looping attack restarts at boundary")
	await key(KEY_ESCAPE)
	check(app.screen == "main" and not paused, "Esc returns to main without leaving tree paused")
	app.find_child("ArtDemoButton", true, false).pressed.emit()
	await tick()
	app.arena.goblin.ai_enabled = false
	check(app.arena.player.art.body.get_size() == Vector2(512, 768), "Existing gameplay retains original renderer")
	check(app.arena.player.character.damage == app.CHARACTERS[0].damage, "Animation proof does not change combat tuning")
	app.queue_free()
	await tick()
	print("ANIMATION LAB: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
