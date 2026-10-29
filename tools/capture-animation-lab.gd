extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.show_animation_lab()
	await process_frame
	var lab = app.find_child("SlayerAnimationLab", true, false)
	lab.toggle_play()
	lab.find_child("AnchorsButton", true, false).button_pressed = true
	for facing: String in ["left", "right"]:
		for action: String in ["idle", "walk", "attack"]:
			lab.select_action(action)
			if lab.large.facing != facing:
				lab.toggle_facing()
			for frame_index in range(6):
				lab.large.seek(frame_index)
				lab.native.seek(frame_index)
				lab._sync_status()
				await process_frame
				await RenderingServer.frame_post_draw
				var image := root.get_texture().get_image()
				image.save_png("res://build/lab-%s-%s-%d.png" % [facing, action, frame_index])
	print("CAPTURE: 36 animation-lab frames saved")
	quit()
