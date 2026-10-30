extends SceneTree
## Full-resolution proof of the same renderer and continuous clock used by Start.
const Visual := preload("res://game/slayer_animation_proof.gd")
var output := "res://build/slayer-detail"
var sample_only := false

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
		if argument == "--sample":
			sample_only = true
	call_deferred("capture")

func capture() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1236,1273)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background := ColorRect.new()
	background.color = Color("#25332f")
	background.size = Vector2(1236,1273)
	viewport.add_child(background)
	var floor_line := Line2D.new()
	floor_line.points = PackedVector2Array([Vector2(0,1110),Vector2(1236,1110)])
	floor_line.default_color = Color("#608375")
	floor_line.width = 2
	viewport.add_child(floor_line)
	var visual := Visual.new()
	visual.scale = Vector2(9.5,9.5)
	visual.repeat_attack = false
	viewport.add_child(visual)
	DirAccess.make_dir_recursive_absolute(output)
	FileAccess.open(output+"/.gdignore",FileAccess.WRITE).store_string("")
	var trace: Array = []
	for facing in ["right","left"]:
		visual.position = Vector2(385 if facing=="right" else 851,1110)
		for sequence in ["combo","run-thrust"]:
			visual.restart()
			var directory: String = output+"/"+sequence+"-"+facing
			DirAccess.make_dir_recursive_absolute(directory)
			for index in range(79 if sequence == "combo" else 68):
				var seconds := index/30.0
				var action := "idle"
				var local := seconds
				if sequence == "combo":
					if seconds >= 0.3 and seconds < 0.9:
						action = "attack1"
						local = seconds-0.3
					elif seconds >= 0.9 and seconds < 1.55:
						action = "attack2"
						local = seconds-0.9
					elif seconds >= 1.55 and seconds < 2.1:
						action = "attack3"
						local = seconds-1.55
				else:
					if seconds >= 0.3 and seconds < 1.2:
						action = "run"
						local = seconds-0.3
					elif seconds >= 1.2 and seconds < 1.83:
						action = "dashattack"
						local = seconds-1.2
				visual.set_motion(action,facing,local,1.0/30.0)
				if sample_only and index not in [0,12,14,17,22,30,34,39,45,49,51,54,60,64]:
					continue
				await process_frame
				await RenderingServer.frame_post_draw
				viewport.get_texture().get_image().save_png(directory+"/%03d.png"%index)
				var p: Dictionary = visual.current_pose()
				trace.append({"sequence":sequence,"facing":facing,"index":index,"time":seconds,"clip":action,"hand":[p["wrist"].x,p["wrist"].y],"sword":p["sword"]})
	FileAccess.open(output+"/trace.json",FileAccess.WRITE).store_string(JSON.stringify(trace,"\t"))
	print("Captured full-resolution Slayer motion: "+output)
	quit()
