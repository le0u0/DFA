extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func screenshot(path: String) -> void:
	await create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func capture() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.show_selection()
	await screenshot("res://build/dungeon-selection.png")
	app.selected_character = app.CHARACTERS[0]
	app.selected = true
	for dungeon in range(2):
		app.dungeon_index = dungeon
		app.start_dungeon()
		for room in range(3):
			for enemy in app.arena.enemies:
				enemy.ai_enabled = false
			if room == 2:
				var boss: DemoFighter = app.arena.enemies[0]
				boss.position = Vector2(720, 430)
				boss.facing = -1
				boss.begin_attack(StringName(boss.enemy_data["special"]), 20.0, 18.0)
			await screenshot("res://build/dungeon-%d-room-%d.png" % [dungeon + 1, room + 1])
			for enemy in app.arena.enemies:
				enemy.take_hit(9999, 1, 0)
			if room < 2:
				app._next_room()
	quit()
