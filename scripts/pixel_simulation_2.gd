@tool
class_name PixelSimulation extends Sprite2D

const size: Vector2i = Vector2i(240, 180)
const empty := Color.TRANSPARENT
const dirt := Color.SIENNA
const water := Color.SKY_BLUE
const pumpkin_seed := Color.GREEN_YELLOW
const gravity: float = .1
const step_interval: float = 0.01

@export_tool_button("Run Setup") var setup: Callable = setup_image

var image: Image
var update_grid: Array[bool]
var velocity_grid: Array[Vector2]

func setup_image() -> void:
	# create the image texture
	image = Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBAF)
	image.fill(empty)
	var rect := Rect2i(0, size.y * 0.7, size.x, size.y * 0.3 + 1)
	image.fill_rect(rect, dirt)
	texture = ImageTexture.create_from_image(image)
	position = size / 2


func _ready() -> void:
	# create the image texture
	setup_image()
	
	update_grid.resize(size.x * size.y)
	update_grid.fill(false)
	
	velocity_grid.resize(size.x * size.y)
	velocity_grid.fill(Vector2.ZERO)
	
	$Step.start(step_interval)


func _physics_process(_delta: float) -> void:
	#if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		#var mouse_pos := _get_mouse_pixel_pos()
		#if (in_sim(mouse_pos)):
			#spawn_pixel(mouse_pos, dirt)
	#if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		#var mouse_pos := _get_mouse_pixel_pos()
		#if (in_sim(mouse_pos)):
			#spawn_pixel(mouse_pos, water)
	pass


# returns false if pixel is out of bounds
func spawn_pixel(pos: Vector2i, color: Color, update := true, velocity := Vector2.DOWN) -> bool:
	if !in_sim(pos): return false
	image.set_pixelv(pos, color)
	set_pixel_update(pos, update)
	set_velocity(pos, velocity)
	texture.update(image)
	return true


func global_to_pixel(global: Vector2) -> Vector2i:
	return Vector2i(to_local(global) + Vector2(size) / 2)


func _get_mouse_pixel_pos() -> Vector2i:
	# get mouse pos relative to top left corner
	var mouse_pos: Vector2i = Vector2i(get_local_mouse_position() + Vector2(size) / 2)
	#mouse_pos = mouse_pos.clamp(Vector2i.ZERO, size - Vector2i.ONE)
	return mouse_pos


func get_velocity(v: Vector2i) -> Vector2:
	return velocity_grid[v.x + v.y * size.x]
	
func set_velocity(v: Vector2i, vel: Vector2) -> void:
	velocity_grid[v.x + v.y * size.x] = vel

func set_pixel_update(v: Vector2i, update: bool) -> void:
	update_grid[v.x + v.y * size.x] = update
	
func get_pixel_update(v: Vector2i) -> bool:
	return update_grid[v.x + v.y * size.x]


func in_sim(v: Vector2i) -> bool:
	return v.x >= 0 and v.y >= 0 and v.x < size.x and v.y < size.y


func swap_pixels(a: Vector2i, b: Vector2i) -> void:
	var col_a := image.get_pixelv(a)
	var col_b := image.get_pixelv(b)
	image.set_pixelv(a, col_b)
	image.set_pixelv(b, col_a)
	set_pixel_update(a, true)
	set_pixel_update(b, true)
	
	# swap veloicty
	var vel_a := get_velocity(a)
	var vel_b := get_velocity(b)
	set_velocity(a, vel_b)
	set_velocity(b, vel_a)
	
	for nei in get_neighbors(a):
		if in_sim(nei):
			set_pixel_update(nei, true)
	for nei in get_neighbors(b):
		if in_sim(nei):
			set_pixel_update(nei, true)
		
func get_neighbors(v: Vector2i) -> Array[Vector2i]:
	var res: Array[Vector2i]
	for x in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.ZERO]:
		for y in [Vector2i.UP, Vector2i.DOWN, Vector2i.ZERO]:	
			res.append(v + x + y)
	return res	

func step_simulation() -> void:
	#var img_out := image.duplicate()
	for y in range(size.y - 1, -1, -1):
		for x in size.x:
			if x % 2 == 1:
				x = size.x - x
			var current := Vector2i(x, y)
			var color := image.get_pixelv(current)
			if color == empty or !get_pixel_update(current):
				continue
				
			set_pixel_update(current, false)
			var down: Vector2i = current + Vector2i.DOWN
			var left: Vector2i = current + Vector2i.LEFT
			var right: Vector2i = current + Vector2i.RIGHT
			var left_down: Vector2i = current + Vector2i.LEFT + Vector2i.DOWN
			var right_down: Vector2i = current + Vector2i.RIGHT + Vector2i.DOWN
			if color == dirt:
				var arr: Array[Vector2i] = [down]
				var lr := [left_down, right_down]
				lr.shuffle()
				arr.append_array(lr)
				for v in arr:
					if in_sim(v) and image.get_pixelv(v) in [empty, water]:
						swap_pixels(current, v)
						break
			elif color == water:
				var arr: Array[Vector2i] = [down]
				var lr := [left_down, right_down]
				lr.shuffle()
				arr.append_array(lr)
				lr = [right, left]
				lr.shuffle()
				arr.append_array(lr)
				for v in arr:
					if in_sim(v) and image.get_pixelv(v) in [empty]:
						swap_pixels(current, v)
						break
			elif color == pumpkin_seed:
				# get position before collision
				var cur_vel := get_velocity(current)
				var new_pos := current
				for j in range(1, round(cur_vel.y) + 1):
					var temp := current + Vector2i(0,j)
					if in_sim(temp) and image.get_pixelv(temp) in [empty, water]:
						new_pos = temp
					else:
						break

				if current != new_pos:
					swap_pixels(current, new_pos)
				else:
					cur_vel.y = 0
				# update velocity		
				cur_vel.y += gravity
				set_velocity(new_pos, cur_vel)
				
						
	#image = img_out
	texture.update(image)

func _on_step_timeout() -> void:
	step_simulation()
