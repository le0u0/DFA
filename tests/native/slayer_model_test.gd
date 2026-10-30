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
	var model: Dictionary = rig.model
	for key: String in visual.data["clips"]:
		var facing := "right" if key.ends_with("_right") else "left"
		var action := key.trim_suffix("_"+facing)
		var clip: Dictionary = visual.data["clips"][key]
		for frame in range(clip["durations"].size()):
			var p: Dictionary = rig.pose(action,facing,frame,visual.data)
			for pair in [["lhip","lknee",model["thigh_length"]],["lknee","lankle",model["shin_length"]],["rhip","rknee",model["thigh_length"]],["rknee","rankle",model["shin_length"]],["shoulder","elbow",model["normal_arm"][0]],["elbow","wrist",model["normal_arm"][1]],["off_shoulder","off_elbow",model["cursed_arm"][0]],["off_elbow","off_wrist",model["cursed_arm"][1]]]:
				check(absf(p[pair[0]].distance_to(p[pair[1]])-float(pair[2]))<0.001,key+" bone length cannot stretch")
			check(absf(p["hip"].distance_to(p["neck"])-float(model["chin_to_hips"]))<0.001,key+" torso length is fixed")
	for facing in ["left","right"]:
		for entry in [["attack1","attack2"],["attack2","attack3"]]:
			var first: Dictionary = visual.data["clips"][entry[0]+"_"+facing]
			var a: Dictionary = rig.pose(entry[0],facing,first["durations"].size()-1,visual.data)
			var b: Dictionary = rig.pose(entry[1],facing,0,visual.data)
			check(a==b,"Whole model pose continues across combo boundaries")
	visual.free()
	print("FIXED SLAYER MODEL: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)
