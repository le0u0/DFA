extends Control
## Isolated art review: independently authored facings, no gameplay state changes.

signal back_requested
const Visual := preload("res://game/slayer_animation_proof.gd")
var large: Node2D
var native: Node2D
var playing := true
var speed := 1.0
var status: Label
var play_button: Button
var facing_button: Button
var weapon_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	large = Visual.new()
	large.position = Vector2(495, 565)
	large.scale = Vector2(3, 3)
	add_child(large)
	native = Visual.new()
	native.position = Vector2(1000, 520)
	add_child(native)
	var box := VBoxContainer.new()
	box.position = Vector2(36, 22)
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	var heading := Label.new()
	heading.text = "Slayer animation lab"
	heading.add_theme_font_size_override("font_size", 32)
	box.add_child(heading)
	var sub := Label.new()
	sub.text = "Chibi motion proof · Idle, walk and basic attack · Separate sword equipment"
	sub.add_theme_font_size_override("font_size", 18)
	box.add_child(sub)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	for action in ["idle", "walk", "attack"]:
		var button := _button(actions, action.capitalize(), action.capitalize() + "Button")
		button.pressed.connect(select_action.bind(action))
	facing_button = _button(actions, "Face left [F]", "FacingButton")
	facing_button.pressed.connect(toggle_facing)
	play_button = _button(actions, "Pause [P]", "PlayButton")
	play_button.pressed.connect(toggle_play)
	_button(actions, "< Frame", "PreviousFrameButton").pressed.connect(step.bind(-1))
	_button(actions, "Frame >", "NextFrameButton").pressed.connect(step.bind(1))
	var options := HBoxContainer.new()
	options.add_theme_constant_override("separation", 12)
	box.add_child(options)
	weapon_button = _button(options, "Sword: Steel [V]", "SwordButton")
	weapon_button.pressed.connect(cycle_weapon)
	var speed_label := Label.new()
	speed_label.text = "Speed"
	options.add_child(speed_label)
	var speed_choice := OptionButton.new()
	speed_choice.name = "SpeedChoice"
	for label in ["0.25×", "0.5×", "1×", "2×"]:
		speed_choice.add_item(label)
	speed_choice.select(2)
	speed_choice.item_selected.connect(func(index: int) -> void: speed = [0.25, 0.5, 1.0, 2.0][index])
	options.add_child(speed_choice)
	var anchors := CheckButton.new()
	anchors.name = "AnchorsButton"
	anchors.text = "Show grip / feet"
	anchors.toggled.connect(func(enabled: bool) -> void:
		for visual in [large, native]:
			visual.show_anchors = enabled
			visual.queue_redraw())
	options.add_child(anchors)
	var loop := CheckButton.new()
	loop.name = "LoopAttackButton"
	loop.text = "Loop attack"
	loop.button_pressed = true
	loop.toggled.connect(func(enabled: bool) -> void:
		for visual in [large, native]:
			visual.repeat_attack = enabled
			visual.restart())
	options.add_child(loop)
	status = Label.new()
	status.name = "FrameStatus"
	status.add_theme_font_size_override("font_size", 18)
	box.add_child(status)
	var back := Button.new()
	back.name = "LabBackButton"
	back.position = Vector2(1065, 28)
	back.size = Vector2(180, 42)
	back.text = "Main menu [Esc]"
	back.pressed.connect(func() -> void: back_requested.emit())
	add_child(back)
	_note("3× inspection", Vector2(80, 270))
	_note("1× gameplay size", Vector2(920, 390))
	_note("1 / 2 / 3: clip     F: facing     P: pause     , / .: step     V: sword / body only", Vector2(36, 620))
	_note("Draft: right windup holds guard. Grip and silhouette need review; combat timing is unchanged.", Vector2(36, 650))
	_sync_status()

func _button(parent: HBoxContainer, label: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.custom_minimum_size = Vector2(112, 40)
	button.add_theme_font_size_override("font_size", 18)
	parent.add_child(button)
	return button

func _note(text: String, point: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = point
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)

func _process(delta: float) -> void:
	if playing:
		large.advance(delta * speed)
		native.advance(delta * speed)
	_sync_status()

func select_action(action: String) -> void:
	for visual in [large, native]:
		visual.select_action(action)
	_sync_status()

func toggle_facing() -> void:
	var direction: String = "left" if large.facing == "right" else "right"
	for visual in [large, native]:
		visual.set_facing(direction)
	facing_button.text = "Face right [F]" if direction == "left" else "Face left [F]"
	_sync_status()

func toggle_play() -> void:
	playing = not playing
	play_button.text = "Pause [P]" if playing else "Play [P]"

func step(amount: int) -> void:
	if playing:
		toggle_play()
	for visual in [large, native]:
		visual.seek(visual.frame + amount)
	_sync_status()

func cycle_weapon() -> void:
	for visual in [large, native]:
		visual.weapon_index = (visual.weapon_index + 1) % 3
		visual.queue_redraw()
	weapon_button.text = "Sword: %s [V]" % ["Steel", "Cyan", "Body only"][large.weapon_index]

func _sync_status() -> void:
	var phase := " · Impact pose" if large.action == "attack" and large.frame == 2 else ""
	status.text = "%s · Facing %s · Frame %d / 6%s" % [large.action.capitalize(), large.facing, large.frame + 1, phase]

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1: select_action("idle")
		KEY_2: select_action("walk")
		KEY_3: select_action("attack")
		KEY_F: toggle_facing()
		KEY_P: toggle_play()
		KEY_COMMA: step(-1)
		KEY_PERIOD: step(1)
		KEY_V: cycle_weapon()
		KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			back_requested.emit()
			return
		_: return
	get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("171e2c"))
	draw_rect(Rect2(36, 245, 1208, 355), Color("202d3f"))
	draw_line(Vector2(100, 565), Vector2(820, 565), Color("596a80"), 1)
	draw_line(Vector2(860, 520), Vector2(1170, 520), Color("596a80"), 1)
