extends Node

const Arena := preload("res://game/arena.gd")
var arena: DemoArena
var ui: Control
var screen := "main"
var health_label: Label
var stats_label: Label
var pause_panel: Control
var selected := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_input()
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.name = "UI"
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var theme := Theme.new()
	theme.default_font_size = 22
	ui.theme = theme
	layer.add_child(ui)
	show_main()

func _register_input() -> void:
	var bindings := {"move_left": KEY_LEFT, "move_right": KEY_RIGHT, "move_up": KEY_UP, "move_down": KEY_DOWN, "attack": KEY_X, "heavy": KEY_Z, "jump": KEY_C, "dash": KEY_SPACE}
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var key := InputEventKey.new()
		key.physical_keycode = bindings[action]
		InputMap.action_add_event(action, key)

func _clear_ui() -> void:
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	pause_panel = null
	get_tree().paused = false

func _clear_arena() -> void:
	if is_instance_valid(arena):
		remove_child(arena)
		arena.queue_free()
	arena = null

func _menu(title: String, subtitle: String) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(520, 0)
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 38)
	box.add_child(heading)
	var sub := Label.new()
	sub.text = subtitle
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	box.add_child(sub)
	return box

func _button(box: VBoxContainer, title: String, node_name: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = title
	button.custom_minimum_size = Vector2(0, 54)
	button.pressed.connect(callback)
	box.add_child(button)
	return button

func show_main() -> void:
	_clear_ui()
	_clear_arena()
	screen = "main"
	var box := _menu("Dungeon Fighter Arad", "Offline side-view combat demo")
	_button(box, "Start", "StartButton", show_selection).grab_focus()
	_button(box, "Quit", "QuitButton", func() -> void: get_tree().quit())

func show_selection() -> void:
	_clear_ui()
	_clear_arena()
	screen = "selection"
	selected = false
	var box := _menu("Character selection", "One playable character in this prototype")
	var fighter := _button(box, "Slayer — sword fighter", "SlayerButton", func() -> void: pass)
	fighter.toggle_mode = true
	var enter := _button(box, "Enter dungeon", "EnterButton", start_dungeon)
	enter.disabled = true
	fighter.pressed.connect(func() -> void:
		selected = fighter.button_pressed
		enter.disabled = not selected
		if selected:
			enter.grab_focus()
	)
	_button(box, "Back", "BackButton", show_main)
	fighter.grab_focus()

func start_dungeon() -> void:
	if not selected:
		return
	_clear_ui()
	_clear_arena()
	screen = "arena"
	arena = Arena.new()
	arena.name = "Dungeon"
	arena.stats_changed.connect(_update_hud)
	arena.player_defeated.connect(_on_defeated)
	_build_hud()
	add_child(arena)

func _build_hud() -> void:
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := MarginContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.add_theme_constant_override("margin_left", 40)
	top.add_theme_constant_override("margin_top", 25)
	top.add_theme_constant_override("margin_right", 40)
	ui.add_child(top)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(box)
	health_label = Label.new()
	box.add_child(health_label)
	stats_label = Label.new()
	box.add_child(stats_label)
	var hint := Label.new()
	hint.text = "Training chamber · The goblin cannot die. Dodge its red wind-up."
	hint.add_theme_font_size_override("font_size", 18)
	box.add_child(hint)
	var pause_button := Button.new()
	pause_button.name = "PauseButton"
	pause_button.text = "Pause [Esc]"
	pause_button.position = Vector2(1070, 28)
	pause_button.custom_minimum_size = Vector2(160, 48)
	pause_button.focus_mode = Control.FOCUS_NONE
	ui.add_child(pause_button)
	pause_button.pressed.connect(pause_game)
	var controls := Label.new()
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	controls.offset_left = 40
	controls.offset_top = -56
	controls.offset_right = -20
	controls.text = "Arrows: move / double-tap: run   X: attack   Z: launcher   C: jump   Space: dodge"
	controls.add_theme_font_size_override("font_size", 18)
	ui.add_child(controls)

func _update_hud(health: int, hits: int, damage: int) -> void:
	health_label.text = "Slayer HP: %d / 100     Goblin HP: ∞" % health
	stats_label.text = "Hits: %d     Total damage: %d" % [hits, damage]

func pause_game() -> void:
	if screen != "arena" or get_tree().paused:
		return
	arena.clear_input()
	get_tree().paused = true
	_show_pause(false)

func _show_pause(defeated: bool) -> void:
	pause_panel = Control.new()
	pause_panel.name = "PausePanel"
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(pause_panel)
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.04, 0.05, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(420, 0)
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	var heading := Label.new()
	heading.text = "You are down" if defeated else "Paused"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	if not defeated:
		_button(box, "Resume", "ResumeButton", resume_game).grab_focus()
	var retry := _button(box, "Restart arena", "RestartButton", start_dungeon)
	if defeated:
		retry.grab_focus()
	_button(box, "Character selection", "SelectionButton", show_selection)
	_button(box, "Main menu", "MainMenuButton", show_main)
	_button(box, "Quit", "QuitButton", func() -> void: get_tree().quit())

func resume_game() -> void:
	if screen != "arena" or arena.player.health <= 0:
		return
	if is_instance_valid(pause_panel):
		ui.remove_child(pause_panel)
		pause_panel.queue_free()
	pause_panel = null
	arena.clear_input()
	get_tree().paused = false

func _on_defeated() -> void:
	arena.clear_input()
	get_tree().paused = true
	_show_pause(true)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if screen == "selection":
			show_main()
		elif screen == "arena":
			if get_tree().paused:
				resume_game()
			else:
				pause_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_instance_valid(arena):
		pause_game()
