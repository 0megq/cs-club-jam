extends Sprite2D

const size: Vector2i = Vector2i(128, 128)
const empty := Color.BLACK
const sand := Color.SANDY_BROWN
const water := Color.SKY_BLUE

var image: Image

func _ready() -> void:
	# create the image texture
	image = Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBAF)
	image.fill(empty)
	texture = ImageTexture.create_from_image(image)


func _physics_process(_delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos := _get_mouse_pixel_pos()
		if (in_sim(mouse_pos)):
			image.set_pixelv(mouse_pos, sand)
			texture.update(image)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var mouse_pos := _get_mouse_pixel_pos()
		if (in_sim(mouse_pos)):
			image.set_pixelv(mouse_pos, water)
			texture.update(image)
	step_simulation()

func _get_mouse_pixel_pos() -> Vector2i:
	# get mouse pos relative to top left corner
	var mouse_pos: Vector2i = Vector2i(get_local_mouse_position() + Vector2(size) / 2)
	#mouse_pos = mouse_pos.clamp(Vector2i.ZERO, size - Vector2i.ONE)
	return mouse_pos


func in_sim(v: Vector2i) -> bool:
	return v.x >= 0 and v.y >= 0 and v.x < size.x and v.y < size.y

func step_simulation() -> void:
	var image_out := image.duplicate()
	for x in size.x:
		for y in size.y:
			var color := image.get_pixel(x, y)
			if color == empty:
				continue
			
			var below: Vector2i = Vector2i(x, y + 1)
			var left: Vector2i = Vector2i(x - 1, y + 1)
			var right: Vector2i = Vector2i(x + 1, y + 1)
			if color == water:
				left.y -= 1
				right.y -= 1
			if in_sim(below) and image.get_pixelv(below) == empty and image_out.get_pixelv(below) == empty:
				image_out.set_pixelv(below, color)
				image_out.set_pixel(x,y, empty)
			elif in_sim(right) and image.get_pixelv(right) == empty and image_out.get_pixelv(right) == empty:
				image_out.set_pixelv(right, color)
				image_out.set_pixel(x,y, empty)
			elif in_sim(left) and image.get_pixelv(left) == empty and image_out.get_pixelv(left) == empty:
				image_out.set_pixelv(left, color)
				image_out.set_pixel(x,y, empty)
	image = image_out
	texture.update(image)
				

func _on_step_pressed() -> void:
	step_simulation()
