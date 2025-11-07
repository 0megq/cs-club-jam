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


func swap_pixels(a: Vector2i, b: Vector2i, img: Image) -> void:
	var col_a := img.get_pixelv(a)
	var col_b := img.get_pixelv(b)
	img.set_pixelv(a, col_b)
	img.set_pixelv(b, col_a)

func step_simulation() -> void:
	var img_out := image.duplicate()
	for x in size.x:
		for y in size.y:
			var current := Vector2i(x, y)
			var color := image.get_pixelv(current)
			if color == empty:
				continue
				
			var down: Vector2i = current + Vector2i.DOWN
			var left: Vector2i = current + Vector2i.LEFT
			var right: Vector2i = current + Vector2i.RIGHT
			var left_down: Vector2i = current + Vector2i.LEFT + Vector2i.DOWN
			var right_down: Vector2i = current + Vector2i.RIGHT + Vector2i.DOWN
			if color == sand:
				var arr: Array[Vector2i] = [down]
				var lr := [left_down, right_down]
				lr.shuffle()
				arr.append_array(lr)
				for v in arr:
					if in_sim(v) and image.get_pixelv(v) in [empty, water]:
						swap_pixels(current, v, img_out)
						break
			elif color == water:
				var arr: Array[Vector2i] = [down]
				var lr := [left_down, right_down]
				lr.shuffle()
				arr.append_array(lr)
				lr = [left, right]
				lr.shuffle()
				arr.append_array(lr)
				for v in arr:
					if in_sim(v) and image.get_pixelv(v) in [empty]:
						swap_pixels(current, v, img_out)
						break
						
	image = img_out
	texture.update(image)
				

func _on_step_pressed() -> void:
	step_simulation()
