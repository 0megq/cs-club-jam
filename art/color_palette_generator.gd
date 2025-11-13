@tool
extends EditorScript


func _run() -> void:
	var img: Image = preload("res://palette.png").get_image()
	var colors: PackedColorArray
	
	var script: String = "extends Node\nconst colors: PackedColorArray = [\n"

	for y in img.get_height():
		for x in img.get_width():
			var col := img.get_pixel(x, y)
			if not col in colors: 
				colors.append(col)
				script += "Color" + str(col) + ",\n"
	script += "]"
	
	var file := FileAccess.open("res://colors.gd", FileAccess.WRITE)
	
	file.store_string(script)
