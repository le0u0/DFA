extends SceneTree
## Deterministic capture of the actual Start renderer. World translation is fixed
## to make pose/timing comparisons readable; actor attack timing remains in use.
const Main := preload("res://scenes/main.tscn")
var output := "res://build/slayer-review-before"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1280, 720)
	var app := Main.instantiate()
	root.add_child(app)
	await process_frame
	app.find_child("StartButton", true, false).pressed.emit()
	app.find_child("SlayerButton", true, false).pressed.emit()
	app.dungeon_index = -1
	app.find_child("EnterButton", true, false).pressed.emit()
	await process_frame
	await process_frame
	var player: DemoFighter = app.arena.player
	app.arena.process_mode = Node.PROCESS_MODE_DISABLED
	player.position = Vector2(500, 400)
	player.flash = 0
	player.invulnerability = 0
	player.jump_height = 0
	var visual: Node2D = player.art
	var traces: Array = []
	for facing in ["right", "left"]:
		for action in ["run", "attack1", "attack2", "attack3", "dashattack"]:
			var directory: String = output + "/" + action + "-" + facing
			DirAccess.make_dir_recursive_absolute(directory)
			for index in range(45):
				var time := index * 0.025
				player.facing = 1 if facing == "right" else -1
				player.running = action == "run"
				player.velocity = Vector2(player.facing * 385, 0) if action == "run" else Vector2.ZERO
				player.combo = int(action.right(1)) if action.begins_with("attack") else 1
				player.attack_kind = &"dash" if action == "dashattack" else &"basic" if action.begins_with("attack") else &""
				var timing: Vector2 = player.character.attack_timing(player.attack_kind, player.combo)
				player.attack_duration = timing.x
				player.strike_time = timing.y
				player.attack_elapsed = time
				player.strike_fired = time >= player.strike_time
				if action != "run" and time >= player.attack_duration:
					player.attack_kind = &""
				visual.slayer_motion = "run" if action == "run" else "dashattack" if action == "dashattack" else action
				visual.slayer_direction = facing
				visual.slayer_time = time
				visual.clock = time
				visual._physics_process(0.0)
				await process_frame
				await RenderingServer.frame_post_draw
				var image := root.get_texture().get_image()
				var origin: Vector2 = player.global_position
				var region := Rect2i(Vector2i(origin) - Vector2i(155, 195), Vector2i(310, 225))
				image.get_region(region).save_png(directory + "/%03d.png" % index)
				traces.append({"action": action, "facing": facing, "time": time, "duration": player.attack_duration, "clip": visual.slayer_visual.action, "frame": visual.frame})
	FileAccess.open(output + "/trace.json", FileAccess.WRITE).store_string(JSON.stringify(traces, "\t"))
	print("Captured actual Start renderer: " + output)
	app.queue_free()
	await process_frame
	quit()
