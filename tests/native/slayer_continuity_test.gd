extends SceneTree
const Visual := preload("res://game/slayer_animation_proof.gd")
var passed := 0
var failed := 0
func check(value: bool, message: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		push_error(message)

func _initialize() -> void:
	var visual := Visual.new()
	var rig = visual.fixed_model
	var step := 1.0/240.0
	for facing in ["right","left"]:
		for action in ["attack1","attack2","attack3","dashattack"]:
			var duration: float = rig.motion["clips"][action][-1][0]
			var previous: Dictionary = rig.pose_time(action,facing,0)
			for i in range(1,int(ceil(duration/step))+1):
				var p: Dictionary = rig.pose_time(action,facing,minf(i*step,duration))
				check(absf(p["sword"]-previous["sword"])<0.4,action+" blade angle cannot snap")
				for joint in ["hip","neck","shoulder","elbow","wrist","off_shoulder","off_elbow","off_wrist","lhip","lknee","lankle","rhip","rknee","rankle"]:
					check(p[joint].is_finite() and p[joint].distance_to(previous[joint])<3.0,action+" continuous "+joint+" at "+str(i*step))
				check(p["view"]==previous["view"],"Attack cannot swap torso textures")
				previous = p
		for pair in [["attack1","attack2"],["attack2","attack3"]]:
			var duration: float = rig.motion["clips"][pair[0]][-1][0]
			check(rig.pose_time(pair[0],facing,duration)==rig.pose_time(pair[1],facing,0),"Complete combo boundary is identical")
		for action in ["attack3","dashattack"]:
			var duration: float = rig.motion["clips"][action][-1][0]
			var last: Dictionary = rig.pose_time(action,facing,duration)
			var idle: Dictionary = rig.pose_time("idle",facing,0)
			check(last==idle,action+" has a complete recovery to guard")
	# In support, the world foot must stay fixed rather than riding with the body.
	for action in ["walk","run"]:
		var speed := 385.0/1.5 if action=="run" else 255.0/1.5
		var stride := 12.0 if action=="run" else 10.0
		var duty := .34 if action=="run" else .52
		var period := 2.0*stride/(speed*duty)
		var first: Dictionary = rig.pose_time(action,"right",period*.05)
		var origin: float = first["lankle"].x+period*.05*speed
		for i in range(6,int(duty*100)-2):
			var t := period*i/100.0
			var p: Dictionary = rig.pose_time(action,"right",t)
			check(absf(p["lankle"].x+t*speed-origin)<0.2,action+" support foot stays planted")
			check(absf(p["lankle"].y+6)<0.2,action+" support foot stays on the floor")
	# Interrupted attacks blend parameters, not assembled joints: anatomy survives.
	for action in ["attack1","attack2","dashattack","idle","run","idle"]:
		for i in range(18):
			visual.set_motion(action,"right",i/120.0,1.0/120.0)
			var p: Dictionary = visual.current_pose()
			check(absf(p["elbow"].distance_to(p["wrist"])-float(rig.model["normal_arm"][1]))<.001,"Transitions preserve arm length")
			check(absf(p["lknee"].distance_to(p["lankle"])-float(rig.model["shin_length"]))<.001,"Transitions preserve leg length")
	for action in ["idle","walk","run"]:
		visual.select_action(action)
		var total := 0.0
		for duration in visual.clip()["durations"]:
			total += float(duration)
		visual.advance(total-.001)
		visual.advance(.002)
		var expected: Dictionary = rig.pose_time(action,"right",total+.001)
		check(visual.current_pose()["wrist"].distance_to(expected["wrist"])<.001,"Continuous clock survives source-record loop boundary")
		check(visual.current_pose()["lankle"].distance_to(expected["lankle"])<.001,"Foot cycle does not restart at ANI loop boundary")
	visual.free()
	print("SLAYER CONTINUITY: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
