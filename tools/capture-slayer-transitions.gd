extends SceneTree
## Records held-input sequences through Start, including actual stage boundaries.
## Only world translation is fixed, so silhouettes share an origin for review.
const Main := preload("res://scenes/main.tscn")
var output := "res://build/slayer-transitions-before"
var traces: Array = []

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1280,720)
	var app := Main.instantiate()
	root.add_child(app)
	await process_frame
	for facing in ["right", "left"]:
		for sequence in ["combo", "run-thrust"]:
			app.show_selection()
			app.find_child("SlayerButton",true,false).pressed.emit()
			app.dungeon_index = -1
			app.find_child("EnterButton",true,false).pressed.emit()
			await physics_frame
			var player: DemoFighter = app.arena.player
			app.arena.goblin.ai_enabled = false
			app.arena.goblin.position = Vector2(1100,590)
			player.facing = 1 if facing == "right" else -1
			var direction: StringName = &"move_right" if facing == "right" else &"move_left"
			var directory: String = output+"/"+sequence+"-"+facing
			DirAccess.make_dir_recursive_absolute(directory)
			var start_tick := Engine.get_physics_frames()
			for index in range(150 if sequence == "combo" else 110):
				if sequence == "combo":
					if index == 8:
						Input.action_press(&"attack")
					if player.combo == 3 and player.attack_elapsed >= player.attack_duration - 0.05:
						Input.action_release(&"attack")
				else:
					if index == 10 or index == 17:
						Input.action_press(direction)
					if index == 13:
						Input.action_release(direction)
					if index == 38:
						Input.action_press(&"attack")
					if index == 40:
						Input.action_release(&"attack")
						Input.action_release(direction)
				await physics_frame
				player.position = Vector2(500,400)
				await process_frame
				await RenderingServer.frame_post_draw
				var body: Node2D = player.art.slayer_visual
				var grip: Vector2 = body.hand_anchor()
				var time := (Engine.get_physics_frames()-start_tick)/60.0
				root.get_texture().get_image().get_region(Rect2i(345,205,310,225)).save_png(directory+"/%03d.png"%index)
				traces.append({"sequence":sequence,"facing":facing,"index":index,"time":time,"kind":String(player.attack_kind),"combo":player.combo,"attack_elapsed":player.attack_elapsed,"clip":body.action,"frame":body.frame,"hand":[grip.x,grip.y],"sword_angle":body.sword_angle()})
			Input.action_release(&"attack")
			Input.action_release(direction)
			await physics_frame
	FileAccess.open(output+"/trace.json",FileAccess.WRITE).store_string(JSON.stringify(traces,"\t"))
	print("Captured held-input combo and idle/run/thrust/idle sequences: "+output)
	app.queue_free()
	await process_frame
	quit()
