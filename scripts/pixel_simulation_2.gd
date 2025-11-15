@tool
class_name PixelSimulation extends Sprite2D

const size: Vector2i = Vector2i(240, 180)
const empty := Color.TRANSPARENT
const wet_dirt := Colors.colors[5-3]
const dirt := Colors.colors[6-3]
const water := Colors.colors[21-3]
const pumpkin_seed := Colors.colors[11-3]
const gravity: float = .1
const step_interval: float = 0.01

@export_tool_button("Run Setup") var setup: Callable = setup_image

var image: Image
var update_grid: Array[bool]
var velocity_grid: Array[Vector2]

# Putting these here, to make my life easier. Might be a bad idea
# These are only to be used within _update_pixel_name functions
var down: Vector2i
var left: Vector2i
var right: Vector2i
var left_down: Vector2i
var right_down: Vector2i
#var down3: Array[Vector2i]
#var down5: Array[Vector2i]

#:setup
func _ready() -> void:
	# create the image texture
	setup_image()
	update_grid.resize(size.x * size.y)
	update_grid.fill(false)
	
	velocity_grid.resize(size.x * size.y)
	velocity_grid.fill(Vector2.ZERO)
	
	$Step.start(step_interval)


func _physics_process(_delta: float) -> void:
	pass


#:setupimage
func setup_image() -> void:
	# create the image texture
	image = Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBAF)
	image.fill(empty)
	var rect := Rect2i(0, size.y * 0.7, size.x, size.y * 0.3 + 1)
	image.fill_rect(rect, dirt)
	var surface := size.y * 0.7
	for x in 30:
		var height = 30 - x
		image.fill_rect(Rect2i(x - 1, surface, 1, height), empty)
	
	#var loaded_image := preload("res://art/map.png").get_image()
	#image = Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBAF)
	#for x in loaded_image.get_width():
		#for y in loaded_image.get_height():
			#var col := loaded_image.get_pixel(x,y)
			#if col.a > 0:
				#image.set_pixel(x,y,col)
			#else:
				#image.set_pixel(x,y,empty)
	texture = ImageTexture.create_from_image(image)
	position = size / 2


#:loopcontrol
func _on_step_timeout() -> void:
	_step_simulation()

#:update
func _step_simulation() -> void:
	for y in range(size.y - 1, -1, -1):
		for x in size.x:
			# pixel selection
			if x % 2 == 1:
				x = size.x - x
			var current := Vector2i(x, y)
			var color := image.get_pixelv(current)
			if color == empty or !get_pixel_update(current):
				continue
			
			down = current + Vector2i.DOWN
			left = current + Vector2i.LEFT
			right = current + Vector2i.RIGHT
			left_down = current + Vector2i.LEFT + Vector2i.DOWN
			right_down = current + Vector2i.RIGHT + Vector2i.DOWN
			
			#down3 = 
			
			set_pixel_update(current, false)
			if color == dirt:
				_update_dirt(current)
			elif color == water:
				_update_water(current)
			elif color == pumpkin_seed:
				_update_pumpkin_seed(current)
			elif color == wet_dirt:
				_update_wet_dirt(current)

	_commit_pixel_updates_to_texture()

func _commit_pixel_updates_to_texture() -> void:
	texture.update(image)

func do_pixel_mouse_placing() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos := get_mouse_pixel_pos()
		if (in_sim(mouse_pos)):
			spawn_pixel(mouse_pos, dirt)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var mouse_pos := get_mouse_pixel_pos()
		if (in_sim(mouse_pos)):
			spawn_pixel(mouse_pos, water)


# returns false if pixel is out of bounds
func spawn_pixel(pos: Vector2i, color: Color, update := true, velocity := Vector2.DOWN) -> bool:
	if !in_sim(pos): return false
	image.set_pixelv(pos, color)
	set_pixel_update(pos, update)
	set_velocity(pos, velocity)
	return true

# Essential Setters and Getters
#func set_pixel(pos: Vector2i, color: Color) -> void:
	#image.set_pixelv(pos, color)
#
#func get_pixel(pos: Vector2i) -> Color:
	#return image.get_pixelv(pos)


func set_velocity(v: Vector2i, vel: Vector2) -> void:
	velocity_grid[v.x + v.y * size.x] = vel

func get_velocity(v: Vector2i) -> Vector2:
	return velocity_grid[v.x + v.y * size.x]


func set_pixel_update(v: Vector2i, update: bool) -> void:
	update_grid[v.x + v.y * size.x] = update

func get_pixel_update(v: Vector2i) -> bool:
	return update_grid[v.x + v.y * size.x]
# END

# Helpers
func is_pixel_empty(v: Vector2i) -> bool:
	return image.get_pixelv(v) == empty

#:coordinate
func global_to_pixel(global: Vector2) -> Vector2i:
	return Vector2i(to_local(global) + Vector2(size) / 2)


func get_mouse_pixel_pos() -> Vector2i:
	# get mouse pos relative to top left corner
	var mouse_pos: Vector2i = Vector2i(get_local_mouse_position() + Vector2(size) / 2)
	#mouse_pos = mouse_pos.clamp(Vector2i.ZERO, size - Vector2i.ONE)
	return mouse_pos

#:bounds
func in_sim(v: Vector2i) -> bool:
	return v.x >= 0 and v.y >= 0 and v.x < size.x and v.y < size.y

		
func get_neighbors(v: Vector2i) -> Array[Vector2i]:
	var res: Array[Vector2i]
	for x in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.ZERO]:
		for y in [Vector2i.UP, Vector2i.DOWN, Vector2i.ZERO]:	
			if x == y: continue
			res.append(v + x + y)
	
	return res	
#END

#:functionality
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
	
	update_neighbors(a)
	update_neighbors(b)


func update_neighbors(v: Vector2i) -> void:
	for nei in get_neighbors(v):
		if in_sim(nei):
			set_pixel_update(nei, true)


# Checks how many pixels of type (in a row) are above v
func how_many_pixels_above(v: Vector2i, type: Color) -> int:
	var y := 0
	v += Vector2i.UP
	while in_sim(v) and image.get_pixelv(v) == type:
		v += Vector2i.UP
		y += 1
	return y


# Individual Pixel Type Update
#:dirt
func _update_dirt(current: Vector2i) -> void:
	var arr: Array[Vector2i] = [down]
	var lr := [left_down, right_down]
	lr.shuffle()
	arr.append_array(lr)
	for v in arr:
		if in_sim(v) and image.get_pixelv(v) in [empty, water]:
			swap_pixels(current, v)
			break

#:water
func _update_water(current: Vector2i) -> void:
	var arr: Array[Vector2i] = [down]
	var lr := [left_down, right_down]
	lr.shuffle()
	arr.append_array(lr)
	var placed := false
	for v in arr:
		if !in_sim(v): continue
		if image.get_pixelv(v) in [empty]:
			swap_pixels(current, v)
			placed = true
			break
	if !placed:
		for v in arr:
			if !in_sim(v): continue
			if image.get_pixelv(v) in [dirt]:
				image.set_pixelv(current, empty)
				image.set_pixelv(v, wet_dirt)
				set_pixel_update(v, true)
				placed = true
				break
	if !placed:
		arr = [right, left]
		arr.shuffle()
		for v in arr:
			if !in_sim(v): continue
			if image.get_pixelv(v) in [empty]:
				swap_pixels(current, v)
				placed = true
				break
	if !placed:
		for v in arr:
			if !in_sim(v): continue
			if image.get_pixelv(v) in [dirt]:
				image.set_pixelv(current, empty)
				image.set_pixelv(v, wet_dirt)
				set_pixel_update(v, true)
				update_neighbors(v)
				placed = true
				break

func _update_wet_dirt(current: Vector2i) -> void:
	var arr: Array[Vector2i] = [down]
	var lr := [left_down, right_down]
	lr.shuffle()
	lr.shuffle()
	lr.shuffle()
	arr.append_array(lr)
	var placed := false
	for v in arr:
		if !in_sim(v): continue
		if image.get_pixelv(v) in [empty, water]:
			swap_pixels(current, v)
			placed = true
			break
	if !placed:
		var distance := how_many_pixels_above(current, wet_dirt)
		var weight := how_many_pixels_above(current + distance * Vector2i.UP, water)
		set_pixel_update(current, true)
		if weight - distance > 0:
			for v in arr:
				if !in_sim(v): continue
				if image.get_pixelv(v) in [dirt]:
					swap_pixels(current, v)
					
					break

#:seed
func _update_pumpkin_seed(current: Vector2i) -> void:
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
