extends SceneTree

func _initialize() -> void:
	var output := FileAccess.open("res://build/macos/GODOT-LICENSES.txt", FileAccess.WRITE)
	if output == null:
		push_error("Cannot write engine licenses")
		quit(1)
		return
	output.store_line("Godot Engine " + Engine.get_version_info()["string"] + "\n")
	output.store_line(Engine.get_license_text())
	output.store_line("\nThird-party copyright notices\n")
	output.store_line(JSON.stringify(Engine.get_copyright_info(), "  "))
	var licenses := Engine.get_license_info()
	for name: String in licenses:
		output.store_line("\n" + name + "\n" + str(licenses[name]))
	output.close()
	quit(0)
