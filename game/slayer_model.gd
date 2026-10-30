extends RefCounted
## One fixed mannequin. Every pose preserves bone lengths and sprite dimensions.
const PARTS := preload("res://assets/characters/slayer/model/parts.png")
const PATH := "res://assets/characters/slayer/model/model.json"
var model: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))

func solve(root: Vector2, goal: Vector2, upper: float, lower: float, bend: float) -> Array[Vector2]:
	var direction := goal - root
	if direction.length() < 0.001:
		direction = Vector2.DOWN
	var distance := clampf(direction.length(), absf(upper - lower) + 0.001, upper + lower - 0.001)
	direction = direction.normalized()
	var along := (upper * upper - lower * lower + distance * distance) / (2.0 * distance)
	var height := sqrt(maxf(upper * upper - along * along, 0.0))
	return [root + direction * along + Vector2(-direction.y, direction.x) * height * bend, root + direction * distance]

func pose(action: String, facing: String, frame: int, data: Dictionary) -> Dictionary:
	var clip: Dictionary = data["clips"][action + "_" + facing]
	var column: int = clip["cells"][frame] if clip.has("cells") else frame
	if column == 0 and clip.has("entry_pose_from"):
		var previous: String = clip["entry_pose_from"]
		var previous_action := previous.trim_suffix("_" + facing)
		return pose(previous_action, facing, data["clips"][previous]["durations"].size() - 1, data)
	var sign := 1.0 if facing == "right" else -1.0
	var hip := Vector2(0, -float(model["hips_to_soles"]))
	var lean := 0.0
	var view := "side"
	var behind := false
	var left_foot := Vector2(-10, -6)
	var right_foot := Vector2(10, -6)
	var head_tilt := 0.0
	var normal_goal := Vector2(sign * 18, -28)
	var cursed_goal := Vector2(-sign * 16, -25)
	if action == "idle":
		hip.y += sin(frame * TAU / 6.0) * 0.3
	elif action == "walk" or action == "run":
		var count: int = clip["durations"].size()
		var phase := frame * TAU / count
		var running := action == "run"
		var stride := 14.0 if running else 9.0
		hip.y = -24 if running else -26
		hip.y += sin(phase * 2) * 0.7
		lean = sign * (0.34 if running else 0.06)
		head_tilt = sign * (0.1 if running else 0.0)
		left_foot = Vector2(-6 + sin(phase) * stride * sign, -6 - maxf(0, cos(phase)) * (7 if running else 3))
		right_foot = Vector2(6 - sin(phase) * stride * sign, -6 - maxf(0, -cos(phase)) * (7 if running else 3))
		normal_goal = Vector2(sign * (17 + sin(phase) * 3), -34 if running else -28)
		cursed_goal = Vector2(-sign * (16 + sin(phase) * 3), -27)
	else:
		var hand: Array = clip["hands"][frame]
		normal_goal = Vector2(hand[0] - 64, hand[1] - 112)
		if action == "attack1":
			if column < 3:
				view = "front"
			else:
				hip = Vector2(sign * 2, -25)
				lean = sign * 0.28
				view = "back" if column >= 4 else "side"
				behind = column >= 4
				left_foot.x = -sign * 12
				right_foot.x = sign * 13
		elif action == "attack2":
			view = "front" if column >= 2 else "side"
			lean = sign * (0.18 if column < 2 else 0.0)
			hip.y = -26 if column < 2 else -28
		elif action == "attack3":
			view = "front" if column < 2 else "side" if column == 2 else "back"
			hip.y = -24 if column < 3 else -28
			lean = sign * (0.14 if column == 2 else -0.04 if column >= 3 else 0.0)
		elif action == "dashattack":
			hip.y = -27 if column < 3 else -24
			lean = sign * (0.06 if column < 3 else 0.36)
			left_foot.x = -sign * (10 if column < 3 else 13)
			right_foot.x = sign * (10 if column < 3 else 14)
			normal_goal = Vector2(sign * (8 if column < 2 else 15 if column == 2 else 35), -46 if column < 3 else -40)
		else:
			# Aerial/skill placeholder poses still use this same fixed anatomy.
			view = "front"
			lean = sign * 0.08
	var neck := hip + Vector2(0, -float(model["chin_to_hips"])).rotated(lean)
	var shoulder_side := -sign if view == "front" or view == "back" else sign
	var shoulder := hip + Vector2(shoulder_side * float(model["shoulder_span"]) / 2, -18).rotated(lean)
	var off_shoulder := hip + Vector2(-shoulder_side * float(model["shoulder_span"]) / 2, -18).rotated(lean)
	if view == "back" and action == "attack3":
		shoulder = hip + Vector2(sign * float(model["shoulder_span"]) / 2, -18).rotated(lean)
		off_shoulder = hip + Vector2(-sign * float(model["shoulder_span"]) / 2, -18).rotated(lean)
	var arm := solve(shoulder, normal_goal, model["normal_arm"][0], model["normal_arm"][1], sign)
	var off_arm := solve(off_shoulder, cursed_goal, model["cursed_arm"][0], model["cursed_arm"][1], -sign)
	var lhip := hip + Vector2(-float(model["hip_span"]) / 2, 0)
	var rhip := hip + Vector2(float(model["hip_span"]) / 2, 0)
	var lleg := solve(lhip, left_foot, model["thigh_length"], model["shin_length"], -sign)
	var rleg := solve(rhip, right_foot, model["thigh_length"], model["shin_length"], -sign)
	return {"hip":hip,"neck":neck,"lean":lean,"head_tilt":head_tilt,"view":view,"behind":behind,"facing":facing,"shoulder":shoulder,"elbow":arm[0],"wrist":arm[1],"off_shoulder":off_shoulder,"off_elbow":off_arm[0],"off_wrist":off_arm[1],"lhip":lhip,"lknee":lleg[0],"lankle":lleg[1],"rhip":rhip,"rknee":rleg[0],"rankle":rleg[1]}

func part(canvas: Node2D, name: String, origin: Vector2, rotation: float, offset: Vector2) -> void:
	var entry: Dictionary = model["parts"][name]
	var rect: Array = entry["rect"]
	var size: Array = entry["size"]
	canvas.draw_set_transform(origin, rotation)
	canvas.draw_texture_rect_region(PARTS, Rect2(offset, Vector2(size[0],size[1])), Rect2(rect[0],rect[1],rect[2],rect[3]))
	canvas.draw_set_transform(Vector2.ZERO)

func bone(canvas: Node2D, name: String, start: Vector2, finish: Vector2, width: float) -> void:
	# Fixed-width anatomical envelopes prevent narrow texture cutouts from
	# making a limb look thinner in a different rotation/view.
	var color := Color("#1e3974")
	if name in ["upper_arm", "forearm"]:
		color = Color("#e2a878")
	elif name.begins_with("cursed"):
		color = Color("#ad3068")
	canvas.draw_line(start,finish,Color("#101423"),width+2)
	canvas.draw_circle(start,(width+2)/2,Color("#101423"))
	canvas.draw_circle(finish,(width+2)/2,Color("#101423"))
	canvas.draw_line(start,finish,color,width)
	canvas.draw_circle(start,width/2,color)
	canvas.draw_circle(finish,width/2,color)
	# The source part size and joint lengths are fixed; no stretching to reach.
	part(canvas, name, start, (finish-start).angle()-PI/2, Vector2(-width/2,-2))

func leg(canvas: Node2D, hip: Vector2, knee: Vector2, ankle: Vector2, facing: String) -> void:
	bone(canvas,"thigh",hip,knee,model["thigh_width"])
	bone(canvas,"shin",knee,ankle,model["shin_width"])
	part(canvas,"boot_"+facing,ankle,0,Vector2(-4 if facing=="right" else -12,-1))

func arm(canvas: Node2D, p: Dictionary, cursed: bool) -> void:
	if cursed:
		bone(canvas,"cursed_upper",p["off_shoulder"],p["off_elbow"],model["cursed_arm_width"][0])
		bone(canvas,"cursed_forearm",p["off_elbow"],p["off_wrist"],model["cursed_arm_width"][1])
		part(canvas,"claw",p["off_wrist"],0,Vector2(-4.5,-2))
		var side := -1.0 if p["off_wrist"].x < p["hip"].x else 1.0
		for index in range(3):
			canvas.draw_arc(p["off_wrist"]+Vector2(side*5,index*3+2),1.3,0,TAU,8,Color("#8793a8"),1.0)
	else:
		bone(canvas,"upper_arm",p["shoulder"],p["elbow"],model["normal_arm_width"][0])
		bone(canvas,"forearm",p["elbow"],p["wrist"],model["normal_arm_width"][1])

func working_hand(canvas: Node2D, p: Dictionary, sword: Texture2D, angle: float) -> void:
	arm(canvas,p,false)
	if sword:
		canvas.draw_set_transform(p["wrist"],angle)
		canvas.draw_texture_rect(sword,Rect2(-12,-48,24,64),false)
		canvas.draw_set_transform(Vector2.ZERO)
	part(canvas,"fist",p["wrist"],angle,Vector2(-3.5,-3.5))

func draw(canvas: Node2D, p: Dictionary, sword: Texture2D, angle: float) -> void:
	leg(canvas,p["lhip"],p["lknee"],p["lankle"],p["facing"])
	leg(canvas,p["rhip"],p["rknee"],p["rankle"],p["facing"])
	arm(canvas,p,true)
	if p["behind"]:
		working_hand(canvas,p,sword,angle)
	part(canvas,"hips_back" if p["view"]=="back" else "hips",p["hip"],p["lean"],Vector2(-16,-4))
	var torso: String = "torso_back" if p["view"]=="back" else "torso_front"
	canvas.draw_set_transform(p["hip"],p["lean"])
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-float(model["chest_width"])/2,-19),Vector2(float(model["chest_width"])/2,-19),Vector2(float(model["waist_width"])/2,0),Vector2(-float(model["waist_width"])/2,0)]),Color("#18316b"))
	canvas.draw_set_transform(Vector2.ZERO)
	var width: float = model["parts"][torso]["size"][0]
	part(canvas,torso,p["hip"],p["lean"],Vector2(-width/2,-float(model["chin_to_hips"])))
	part(canvas,"head_back" if p["view"]=="back" and p["behind"]==false else "head_"+p["facing"],p["neck"],p["head_tilt"],Vector2(-float(model["head"][0])/2,-float(model["head"][1])))
	if not p["behind"]:
		working_hand(canvas,p,sword,angle)
