extends RefCounted
## Fixed anatomy with continuous motion, stable joint poles and planted support feet.
const PARTS := preload("res://assets/characters/slayer/model/parts.png")
const PATH := "res://assets/characters/slayer/model/model.json"
const MOTION_PATH := "res://assets/characters/slayer/model/motion.json"
var model: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
var motion: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MOTION_PATH))

func solve(root: Vector2, goal: Vector2, upper: float, lower: float, bend: float) -> Array[Vector2]:
	var direction := goal - root
	if direction.length() < 0.001:
		direction = Vector2.DOWN
	# Keep a small bend at full reach instead of allowing the elbow/knee to lock.
	var distance := clampf(direction.length(), absf(upper - lower) + 0.05, upper + lower - 0.12)
	direction = direction.normalized()
	var along := (upper * upper - lower * lower + distance * distance) / (2.0 * distance)
	var height := sqrt(maxf(upper * upper - along * along, 0.0))
	return [root + direction * along + Vector2(-direction.y, direction.x) * height * bend, root + direction * distance]

func _slope(keys: Array, index: int, channel: int) -> float:
	if index == 0 or index == keys.size()-1:
		return 0.0
	var a: float = (float(keys[index][channel])-float(keys[index-1][channel])) / (float(keys[index][0])-float(keys[index-1][0]))
	var b: float = (float(keys[index+1][channel])-float(keys[index][channel])) / (float(keys[index+1][0])-float(keys[index][0]))
	if a*b <= 0:
		return 0.0
	return 2.0*a*b/(a+b)

func sample(action: String, seconds: float) -> Array:
	var keys: Array = motion["clips"].get(action, [])
	if keys.is_empty():
		return motion["guard"].duplicate()
	if seconds <= 0:
		return keys[0].slice(1)
	if seconds >= float(keys[-1][0]):
		return keys[-1].slice(1)
	var i := 0
	while seconds > float(keys[i+1][0]):
		i += 1
	var span: float = float(keys[i+1][0])-float(keys[i][0])
	var t: float = (seconds-float(keys[i][0]))/span
	var result: Array = []
	for c in range(1, keys[i].size()):
		var a: float = keys[i][c]
		var b: float = keys[i+1][c]
		result.append((2*t*t*t-3*t*t+1)*a + (t*t*t-2*t*t+t)*span*_slope(keys,i,c) + (-2*t*t*t+3*t*t)*b + (t*t*t-t*t)*span*_slope(keys,i+1,c))
	return result

func _foot(phase: float, stride: float, lift: float, duty: float) -> Vector2:
	var t := fposmod(phase, 1.0)
	if t < duty:
		# Linear backward travel cancels world motion for the planted foot.
		return Vector2(lerpf(stride, -stride, t/duty), -6)
	var u := (t-duty)/(1-duty)
	return Vector2(lerpf(-stride, stride, smoothstep(0,1,u)), -6-pow(sin(PI*u),2)*lift)

func parameters(action: String, seconds: float, speed := 0.0) -> Dictionary:
	var v: Array = sample(action,seconds)
	var p := {"hip":Vector2(v[3],v[4]),"lean":float(v[5]),"hand":Vector2(v[0],v[1]),"off":Vector2(v[6],v[7]),"left_foot":Vector2(v[8],-6),"right_foot":Vector2(v[9],-6),"head_tilt":0.0,"sword":float(v[2])}
	if action == "attack1" and seconds > .04 and seconds < .15:
		p["right_foot"].y -= pow(sin(PI*(seconds-.04)/.11),2)*3
	elif action == "attack3" and seconds > .35 and seconds < .55:
		p["right_foot"].y -= pow(sin(PI*(seconds-.35)/.20),2)*2
	if action == "idle":
		var breath := sin(seconds*TAU/2.4)*0.25
		p["hip"].y += breath
		p["hand"].y += breath
		p["off"].y += breath
	elif action in ["walk","run"]:
		var running := action == "run"
		var stride := 12.0 if running else 10.0
		var duty := 0.34 if running else 0.52
		var local_speed := speed if speed > 0.1 else (385.0/1.5 if running else 255.0/1.5)
		var period := 2.0*stride/(duty*local_speed)
		var phase := seconds/period
		var a := _foot(phase,stride,7 if running else 3,duty)
		var b := _foot(phase+0.5,stride,7 if running else 3,duty)
		p["left_foot"] = a+Vector2(-5,0)
		p["right_foot"] = b+Vector2(5,0)
		p["hip"] = Vector2(0,-21.8+cos(phase*TAU*2)*0.4 if running else -23.4+cos(phase*TAU*2)*0.3)
		p["lean"] = 0.18 if running else 0.04
		p["head_tilt"] = -0.05 if running else -0.01
		p["hand"] = Vector2(15+sin(phase*TAU)*4,-37 if running else -32)
		p["off"] = Vector2(-15-sin(phase*TAU)*4,-32 if running else -29)
		p["sword"] = 0.48+sin(phase*TAU)*0.08
	return p

func blend(a: Dictionary, b: Dictionary, weight: float) -> Dictionary:
	var result: Dictionary = {}
	for key in b:
		result[key] = lerp(a[key],b[key],weight)
	return result

func assemble(parameters_value: Dictionary, facing: String) -> Dictionary:
	var p: Dictionary = parameters_value.duplicate(true)
	var sign := 1.0 if facing == "right" else -1.0
	for key in ["hip","hand","off","left_foot","right_foot"]:
		p[key].x *= sign
	var hip: Vector2 = p["hip"]
	var lean: float = p["lean"]*sign
	var neck := hip+Vector2(0,-float(model["chin_to_hips"])).rotated(lean)
	# Shoulder identity never switches when a clip changes. The three-quarter
	# torso remains continuous; an attack is not an instantaneous 180-degree turn.
	var shoulder := hip+Vector2(8*sign,-18).rotated(lean)
	var off_shoulder := hip+Vector2(-10*sign,-18).rotated(lean)
	var arm := solve(shoulder,p["hand"],model["normal_arm"][0],model["normal_arm"][1],sign)
	var off_arm := solve(off_shoulder,p["off"],model["cursed_arm"][0],model["cursed_arm"][1],-sign)
	var lhip := hip+Vector2(-float(model["hip_span"])/2*sign,0)
	var rhip := hip+Vector2(float(model["hip_span"])/2*sign,0)
	var lleg := solve(lhip,p["left_foot"],model["thigh_length"],model["shin_length"],-sign)
	var rleg := solve(rhip,p["right_foot"],model["thigh_length"],model["shin_length"],-sign)
	return {"hip":hip,"neck":neck,"lean":lean,"head_tilt":p["head_tilt"]*sign,"view":"side","behind":false,"facing":facing,"sword":p["sword"]*sign,"shoulder":shoulder,"elbow":arm[0],"wrist":arm[1],"off_shoulder":off_shoulder,"off_elbow":off_arm[0],"off_wrist":off_arm[1],"lhip":lhip,"lknee":lleg[0],"lankle":lleg[1],"rhip":rhip,"rknee":rleg[0],"rankle":rleg[1]}

func pose_time(action: String, facing: String, seconds: float, speed := 0.0) -> Dictionary:
	return assemble(parameters(action,seconds,speed),facing)

func pose(action: String, facing: String, frame: int, data: Dictionary) -> Dictionary:
	var clip: Dictionary = data["clips"][action+"_"+facing]
	var seconds := 0.0
	for index in range(frame):
		seconds += float(clip["durations"][index])
	# Frame-seek compatibility; playback itself samples the continuous clock.
	if frame == clip["durations"].size()-1 and motion["clips"].has(action):
		seconds = float(motion["clips"][action][-1][0])
	return pose_time(action,facing,seconds)

func part(canvas: Node2D, name: String, origin: Vector2, rotation: float, offset: Vector2, mirror := false) -> void:
	var entry: Dictionary = model["parts"][name]
	var rect: Array = entry["rect"]
	var size: Array = entry["size"]
	canvas.draw_set_transform(origin,rotation,Vector2(-1,1) if mirror else Vector2.ONE)
	canvas.draw_texture_rect_region(PARTS,Rect2(offset,Vector2(size[0],size[1])),Rect2(rect[0],rect[1],rect[2],rect[3]))
	canvas.draw_set_transform(Vector2.ZERO)

func bone(canvas: Node2D, name: String, start: Vector2, finish: Vector2, width: float) -> void:
	var entry: Dictionary = model["parts"][name]
	var root_values: Array = entry.get("root",[width/2,2])
	var tip_values: Array = entry.get("tip",[width/2,entry["size"][1]-2])
	var pivot := Vector2(root_values[0],root_values[1])
	var axis := Vector2(tip_values[0],tip_values[1])-pivot
	var uniform_scale := start.distance_to(finish)/axis.length()
	canvas.draw_set_transform(start,(finish-start).angle()-axis.angle(),Vector2.ONE*uniform_scale)
	var rect: Array = entry["rect"]
	var size_values: Array = entry["size"]
	canvas.draw_texture_rect_region(PARTS,Rect2(-pivot,Vector2(size_values[0],size_values[1])),Rect2(rect[0],rect[1],rect[2],rect[3]))
	canvas.draw_set_transform(Vector2.ZERO)

func leg(canvas: Node2D, hip: Vector2, knee: Vector2, ankle: Vector2, facing: String) -> void:
	bone(canvas,"thigh",hip,knee,model["thigh_width"])
	bone(canvas,"shin",knee,ankle,model["shin_width"])
	part(canvas,"boot_"+facing,ankle,0,Vector2(-6 if facing=="right" else -12,-6))

func arm(canvas: Node2D, p: Dictionary, cursed: bool) -> void:
	if cursed:
		bone(canvas,"cursed_upper",p["off_shoulder"],p["off_elbow"],model["cursed_arm_width"][0])
		bone(canvas,"cursed_forearm",p["off_elbow"],p["off_wrist"],model["cursed_arm_width"][1])
		part(canvas,"claw",p["off_wrist"],0,Vector2(-5.5,-1),p["facing"]=="left")
	else:
		bone(canvas,"upper_arm",p["shoulder"],p["elbow"],model["normal_arm_width"][0])
		bone(canvas,"forearm",p["elbow"],p["wrist"],model["normal_arm_width"][1])

func working_hand(canvas: Node2D, p: Dictionary, sword: Texture2D, angle: float) -> void:
	bone(canvas,"forearm",p["elbow"],p["wrist"],model["normal_arm_width"][1])
	if sword:
		var name := "sword_cyan" if "cyan" in sword.resource_path else "sword_steel"
		if model["parts"].has(name):
			part(canvas,name,p["wrist"],angle,Vector2(-4,-54))
		else:
			canvas.draw_set_transform(p["wrist"],angle)
			canvas.draw_texture_rect(sword,Rect2(-12,-48,24,64),false)
			canvas.draw_set_transform(Vector2.ZERO)
	part(canvas,"fist",p["wrist"],angle,Vector2(-3.5,-3.5))

func draw(canvas: Node2D, p: Dictionary, sword: Texture2D, angle: float) -> void:
	leg(canvas,p["lhip"],p["lknee"],p["lankle"],p["facing"])
	leg(canvas,p["rhip"],p["rknee"],p["rankle"],p["facing"])
	arm(canvas,p,true)
	arm(canvas,p,false)
	part(canvas,"hips",p["hip"],p["lean"]*0.35,Vector2(-16,-4),p["facing"]=="left")
	part(canvas,"torso_front",p["hip"],p["lean"],Vector2(-20,-float(model["chin_to_hips"])),p["facing"]=="left")
	part(canvas,"head_"+p["facing"],p["neck"]+Vector2(0,3.5),p["head_tilt"],Vector2(-float(model["head"][0])/2,-float(model["head"][1])))
	working_hand(canvas,p,sword,angle)
