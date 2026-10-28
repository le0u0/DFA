extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.start_art_demo()
	app.arena.goblin.ai_enabled = false
	app.arena.player.position = Vector2(550, 450)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/slayer-art-demo.png")
	app.arena.player.art.cycle_weapon()
	app.arena.player.begin_attack(&"basic", 1.2, 0.4)
	await create_timer(0.45).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/slayer-art-attack.png")
	await create_timer(1.0).timeout
	app.arena.player.facing = -1
	app.arena.player.begin_attack(&"basic", 1.2, 0.4)
	await create_timer(0.45).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/slayer-art-left.png")
	quit()
