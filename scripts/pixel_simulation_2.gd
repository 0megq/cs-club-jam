@tool
class_name PixelSimulation extends Sprite2D

const size: Vector2i = Vector2i(240, 180)
const empty := Color.TRANSPARENT
const wet_dirt := Colors.colors[5-3]
const dirt := Colors.colors[6-3]
const water := Colors.colors[21-3]
const pumpkin_seed := Colors.colors[11-3]
const sprout := Colors.colors[12-3]
const plant := Colors.colors[13-3]
const leaf := Colors.colors[14-3]
const dying_plant := Colors.colors[33-3]
const gravity: float = .1
const step_interval: float = 0.01
const step_freq: float = 1 / step_interval
class Plant:
	var state: int = 0
	var state_start_time: float
	var next: Vector2i
	var leaf_to_grow: Vector2i
	var leaf_growth_this_stage: int = 0
	var growth_this_stage: int = 0
	var hurt_times: float = 0
	var plant_height: int = 0
	var leaves: int = 0

@export_tool_button("Run Setup") var setup: Callable = setup_image

var plants_created: int = 0
var plants_alive: int = 0
var image: Image
var update_grid: Array[bool]
var velocity_grid: Array[Vector2]
var plants: Dictionary[Vector2i, Plant]

# Putting these here, to make my life easier. Might be a bad idea
# These are only to be used within _update_pixel_name functions
var down: Vector2i
var left: Vector2i
var right: Vector2i
var left_down: Vector2i
var right_down: Vector2i
var down3: Array[Vector2i]
var down5: Array[Vector2i]
var sides: Array[Vector2i]

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
	var surface := int(size.y * 0.7)
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
	plants_alive = 0
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
			
			down3 = [down]
			var temp = [left_down, right_down]
			temp.shuffle()
			down3.append_array(temp)
			
			for i in range(down3.size() - 1, -1, -1):
				if in_sim(down3[i]): continue
				down3.remove_at(i)
						
			sides = [left, right]
			sides.shuffle()
			for i in range(sides.size() - 1, -1, -1):
				if in_sim(sides[i]): continue
				sides.remove_at(i)
			
			down5 = down3 + sides		
			
			
			set_pixel_update(current, false)
			match color:
				dirt:
					_update_dirt(current)
				water:
					_update_water(current)
				wet_dirt:
					_update_wet_dirt(current)
				pumpkin_seed:
					_update_pumpkin_seed(current)
				sprout:
					_update_sprout(current)
				dying_plant:
					_update_dying_plant(current)
				#leaf:
					#set_pixel_update(current, true)
					#var has_friend := false
					#for nei in get_neighbors8(current):
						#if pixel_in(nei, [sprout, leaf, plant]):
							#has_friend = true
					#if !has_friend:
						#image.set_pixelv(current, dying_plant)
				#plant:
					#set_pixel_update(current, true)
					#var has_friend := false
					#for nei in get_neighbors8(current):
						#if pixel_in(nei, [sprout, leaf, plant]):
							#has_friend = true
					#if !has_friend:
						#image.set_pixelv(current, dying_plant)
						
						
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

# For external use only
func set_pixel(pos: Vector2i, color: Color) -> void:
	image.set_pixelv(pos, color)
# For external use only
func get_pixel(pos: Vector2i) -> Color:
	return image.get_pixelv(pos)


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
	return in_sim(v) and image.get_pixelv(v) == empty

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

func get_down3(v: Vector2i) -> Array[Vector2i]:
	var arr: Array[Vector2i] = [v + Vector2i.DOWN]
	var temp: Array[Vector2i] = [v + Vector2i(1, 1), v + Vector2i(-1, 1)]
	temp.shuffle()
	arr.append_array(temp)
	
	return arr

func get_down5(v: Vector2i) -> Array[Vector2i]:
	var arr: Array[Vector2i] = get_down3(v)
	var temp: Array[Vector2i] = [v + Vector2i(1, 0), v + Vector2i(-1, 0)]
	temp.shuffle()
	arr.append_array(temp)
	
	return arr
		

func get_neighbors24(v: Vector2i) -> Array[Vector2i]:
	var res: Array[Vector2i]
	for x in [-2, -1, 0, 1, 2]:
		for y in [-2, -1, 0, 1, 2]:
			if x==y: continue
			res.append(v + Vector2i(x,y))
	return res

func get_neighbors8(v: Vector2i) -> Array[Vector2i]:
	return [v + Vector2i.LEFT, v + Vector2i.RIGHT, v + Vector2i.DOWN, v + Vector2i.UP, v + Vector2i(1, 1), v + Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)]

func get_neighbors4(v: Vector2i) -> Array[Vector2i]:
	return [v + Vector2i.LEFT, v + Vector2i.RIGHT, v + Vector2i.DOWN, v + Vector2i.UP]

func pixel_in(v: Vector2i, arr: PackedColorArray) -> bool:
	return in_sim(v) and image.get_pixelv(v) in arr

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
	
	update_neighbors8(a)
	update_neighbors8(b)


func update_neighbors8(v: Vector2i) -> void:
	for nei in get_neighbors8(v):
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


# v should be the location of a wet_dirt pixel. returns v if nothing is found
func find_first_dry_dirt(start: Vector2i, dist: int) -> Vector2i:
	# breadth first search starting from v and out dist
	# prefer sides first over down
	# we can go up, but only as long as the y value is at or below 1 + v.y

	# the values of this array are vectors of (distance from v, and height relative to v)
	var nodes: Dictionary[Vector2i, Vector2i]
	var explore_next: Array[Vector2i]
	var exploring: Array[Vector2i]
	explore_next = [start]
	nodes[start] = Vector2i(0, 0)
	
	while (!explore_next.is_empty()):
		exploring = explore_next.duplicate()
		explore_next.clear()
		
		var next: Vector2i
		var next_col: Color
		# left and right
		for v in exploring:
			# this node is already on the edge, don't explore
			if nodes[v].x >= dist: continue
			
			# go left
			next = v + Vector2i.LEFT
			if !next in nodes: # if we haven't come across this node already -> try it
				if !in_sim(next):
					# if out of bounds add it to explored
					nodes[next] = Vector2i(nodes[v].x + 1, nodes[v].y)
				else:
					next_col = image.get_pixelv(next)
					if next_col == dirt:
						# if dirt, return that value immediately
						return next
					elif next_col == wet_dirt:
						# if wet add it to explore_next (if not already in the dictionary) and store distance and height
						nodes[next] = Vector2i(nodes[v].x + 1, nodes[v].y)
						explore_next.append(next)
					else:
						# if not add it to explored (AKA add to dict)
						nodes[next] = Vector2i(nodes[v].x + 1, nodes[v].y)
			
			# go right
			next = v + Vector2i.RIGHT
			if !next in nodes: # if we haven't come across this node already -> try it
				if !in_sim(next):
					# if out of bounds add it to explored
					nodes[next] = Vector2i(nodes[v].x + 1, nodes[v].y)
				else:
					next_col = image.get_pixelv(next)
					if next_col == dirt:
						# if dirt, return that value immediately
						return next
					elif next_col == wet_dirt:
						# if wet add it to explore_next (if not already in the dictionary) and store distance and height
						nodes[next] = Vector2i(nodes[v].x + 1, nodes[v].y)
						explore_next.append(next)
					else:
						# if not add it to explored (AKA add to dict)
						nodes[next] = Vector2i(nodes[v].x + 1, nodes[v].y)
		
		# down
		for v in exploring:
			# already at edge
			if nodes[v].x >= dist: continue
			
			# go down
			next = v + Vector2i.DOWN
			if !next in nodes: # if we haven't come across this node already -> try it
				if !in_sim(next):
					# if out of bounds add it to explored
					nodes[next] = Vector2i(nodes[v].x + 1, nodes[v].y - 1)
				else:
					next_col = image.get_pixelv(next)
					if next_col == dirt:
						# if dirt, return that value immediately
						return next
					elif next_col == wet_dirt:
						# if wet add it to explore_next (if not already in the dictionary) and store distance and height
						nodes[next] = Vector2i(nodes[v].x + 1, nodes[v].y - 1)
						explore_next.append(next)
					else:
						# if not add it to explored (AKA add to dict)
						nodes[next] = Vector2i(nodes[v].x + 1, nodes[v].y - 1)
		
		# up
		for v in exploring:
			# already at edge or too high
			if nodes[v].x >= dist or nodes[v].y >= 2: continue
			
			# go up
			next = v + Vector2i.UP
			if !next in nodes: # if we haven't come across this node already -> try it
				if !in_sim(next):
					# if out of bounds add it to explored
					nodes[next] = Vector2i(nodes[v].x + 1, nodes[v].y + 1)
				else:
					next_col = image.get_pixelv(next)
					if next_col == dirt:
						# if dirt, return that value immediately
						return next
					elif next_col == wet_dirt:
						# if wet add it to explore_next (if not already in the dictionary) and store distance and height
						nodes[next] = Vector2i(nodes[v].x + 1, nodes[v].y + 1)
						explore_next.append(next)
					else:
						# if not add it to explored (AKA add to dict)
						nodes[next] = Vector2i(nodes[v].x + 1, nodes[v].y + 1)
	
	
	return start

func get_wet_dirt_touching_plant(start: Vector2i) -> Vector2i:
	# check for wet dirt around start
	
	var plant_exploring: Array[Vector2i] = [start]
	var plant_to_explore: Array[Vector2i]
	
	for nei in get_neighbors24(start):
		if in_sim(nei) and pixel_in(nei, [wet_dirt]): return nei
	for nei in get_neighbors8(start):
		if in_sim(nei) and pixel_in(nei, [plant]): plant_to_explore.append(nei)
		
	
	while !plant_to_explore.is_empty():
		plant_exploring = plant_to_explore.duplicate()
		plant_to_explore.clear()
		
		for p in plant_exploring:
			for nei in get_neighbors24(p):
				if in_sim(nei) and pixel_in(nei, [wet_dirt]): return nei
			for nei in get_down3(p):
				if in_sim(nei) and pixel_in(nei, [plant]): plant_to_explore.append(nei)
	
	return start

func get_first_available_leaf_spot(start: Vector2i) -> Vector2i:
	# go up check left, left down, and right + right down
	var current := start + Vector2i.UP
	while image.get_pixelv(current) == plant:
		var x: int = [-1, 1].pick_random()
		var side := Vector2i(current.x + x, current.y)
		var side_down := Vector2i(side.x, side.y + 1)
		if in_sim(side) and in_sim(side_down) and is_pixel_empty(side) and is_pixel_empty(side_down):
			return side
		side.x += -2 * x
		side_down.x += -2 * x
		if in_sim(side) and in_sim(side_down) and is_pixel_empty(side) and is_pixel_empty(side_down):
			return side		
		current = current + Vector2i.UP
		
	return start

func get_plant_pixels(start: Vector2i) -> Array[Vector2i]:
	var plant_pixels: Array[Vector2i]
	var plant_exploring: Array[Vector2i]
	var plant_to_explore: Array[Vector2i] = [start]
	while !plant_to_explore.is_empty():
		plant_exploring = plant_to_explore.duplicate()
		plant_pixels.append_array(plant_to_explore)
		plant_to_explore.clear()
		
		for p in plant_exploring:
			for nei in get_neighbors8(p):
				if in_sim(nei) and pixel_in(nei, [plant, leaf]) and !nei in plant_pixels: plant_to_explore.append(nei)

	return plant_pixels

# Individual Pixel Type Update
#:dirt
func _update_dirt(current: Vector2i) -> void:
	# fill empty/water below
	for v in down3:
		if !pixel_in(v, [empty, water]): continue
		
		swap_pixels(current, v)
		break

#:water
func _update_water(current: Vector2i) -> void:
	# fill empty space below
	for v in [down]:
		if !pixel_in(v, [empty]): continue
		
		swap_pixels(current, v)
		return
	
	# wet dirt below
	for v in [down]:
		if !pixel_in(v, [dirt]): continue
		
		image.set_pixelv(current, empty)
		image.set_pixelv(v, wet_dirt)
		update_neighbors8(current)
		update_neighbors8(v)
		return
		
	# fill empty space below
	for v in down3:
		if !pixel_in(v, [empty]): continue
		
		swap_pixels(current, v)
		return
	
	# wet dirt below
	for v in down3:
		if !pixel_in(v, [dirt]): continue
		
		image.set_pixelv(current, empty)
		image.set_pixelv(v, wet_dirt)
		update_neighbors8(current)
		update_neighbors8(v)
		return
	
	# wet dirt adjacent to wet dirt
	
	for v in down3:
		if !pixel_in(v, [wet_dirt]): continue
		# for each pixel in the diamond, starting from insde out and sides down		
		var next := find_first_dry_dirt(v, 5)
		if next == v: continue # dirt wasn't found so the function returned the start point
		image.set_pixelv(current, empty)
		image.set_pixelv(next, wet_dirt)
		update_neighbors8(current)
		update_neighbors8(next)
		
		return
	# fill empty space on sides
	for v in sides:
		if !pixel_in(v, [empty]): continue
		
		swap_pixels(current, v)
		return
	
	# wet dirt on sides
	for v in sides:
		if !pixel_in(v, [dirt]): continue
		
		image.set_pixelv(current, empty)
		image.set_pixelv(v, wet_dirt)
		set_pixel_update(v, true)
		update_neighbors8(v)
		return

func _update_wet_dirt(current: Vector2i) -> void:
	for v in down3:
		if !pixel_in(v, [empty, water]): continue
		
		swap_pixels(current, v)
		return
	#var distance := how_many_pixels_above(current, wet_dirt)
	#var weight := how_many_pixels_above(current + distance * Vector2i.UP, water)
	#set_pixel_update(current, true)
	#if weight - distance <= 0: return
	#for v in down3:
		#if !pixel_in(v, [dirt]): continue
		#swap_pixels(current, v)
		#return

#:seed
func _update_pumpkin_seed(current: Vector2i) -> void:
	set_pixel_update(current, true)
	# get position before collision
	var cur_vel := get_velocity(current)
	var new_pos := current
	# TODO: extract this logic out
	for j in range(1, round(cur_vel.y) + 1):
		var temp := current + Vector2i(0,j)
		if in_sim(temp) and pixel_in(temp, [empty, water]):
			new_pos = temp
		elif in_sim(temp) and pixel_in(temp, [dirt, wet_dirt]):
			new_pos = temp
			cur_vel.y = max(cur_vel.y - 2, 0)
		else:
			break

	if current != new_pos:
		swap_pixels(current, new_pos)
	else:
		cur_vel.y = 0
		# check to see if surrounded by 2 wet dirt
		var wet_dirt_counter := 0
		for nei in get_neighbors4(current):
			if pixel_in(nei, [wet_dirt]):
				wet_dirt_counter += 1

		if wet_dirt_counter >= 2:
			image.set_pixelv(current, sprout)
			plants_created += 1
			set_pixel_update(current, true)
		
		
	# update velocity	
	cur_vel.y += gravity
	set_velocity(new_pos, cur_vel)

#:sprout
func _update_sprout(current: Vector2i) -> void:
	# sprout needs to do something now
	if !current in plants:
		plants[current] = Plant.new()
		plants[current].state = 0
		plants[current].state_start_time = Time.get_ticks_msec()
		plants[current].growth_this_stage = 0
		plants[current].leaf_growth_this_stage = 0
		plants[current].leaf_to_grow = -Vector2i.ONE
	else:
		var plant_data := plants[current]
		# after 1 second, the pixel will try to grow once and consume a wet dirt
		# then wait like 10-20 seconds for more growth
		match plant_data.state:
			0:
				if Time.get_ticks_msec() - plant_data.state_start_time > 3000:
					# grow a new thing
					var neighbors := get_neighbors8(current)
					neighbors.shuffle()
					var new_guy: Vector2i
					var new_guy_grew: bool = false
					for nei in neighbors:
						if !in_sim(nei) or !pixel_in(nei, [wet_dirt]): continue
						image.set_pixelv(nei, plant)
						new_guy = nei
						new_guy_grew = true
						update_neighbors8(new_guy)
						break
					
					if new_guy_grew:
						# go to next stage
						plant_data.state += 1
						plant_data.state_start_time = Time.get_ticks_msec()
						plant_data.next = [current, new_guy].pick_random()		
						plant_data.growth_this_stage = 0
					else:
						kill_plant(current)
						pass
			1:
				if Time.get_ticks_msec() - plant_data.state_start_time > 3000:
					var new_guy: Vector2i
					var new_guy_grew: bool = false
					var _down3 := get_down3(plant_data.next)
					_down3.shuffle()
					for nei in _down3:
						if !in_sim(nei) or !pixel_in(nei, [wet_dirt]): continue
						image.set_pixelv(nei, plant)
						new_guy = nei
						new_guy_grew = true
						update_neighbors8(new_guy)
						break
					if new_guy_grew:
						image.set_pixelv(new_guy, plant)
						plant_data.next = new_guy
						plant_data.state_start_time = Time.get_ticks_msec()
						plant_data.growth_this_stage += 1
					else:
						plant_data.hurt_times += 1
						plant_data.state_start_time = Time.get_ticks_msec()
						if plant_data.hurt_times > 2:
							kill_plant(current)
						# reset timer and try to grow again X times and then show signs of unhealth
				if plant_data.growth_this_stage > 2:
					plant_data.state += 1
					plant_data.state_start_time = Time.get_ticks_msec()
					plant_data.next = current
					plant_data.growth_this_stage = 0
					plant_data.hurt_times = 0
			2:
				if Time.get_ticks_msec() - plant_data.state_start_time > 1000:
					var new_guy: Vector2i = plant_data.next + Vector2i.UP
					#new_guy.x += [-1, 0, 1].pick_random()
					if pixel_in(new_guy, [wet_dirt]):
						image.set_pixelv(new_guy, plant)
						plant_data.next = new_guy
						plant_data.state_start_time = Time.get_ticks_msec()
						plant_data.growth_this_stage += 1
						update_neighbors8(new_guy)
					else:
						var my_dirt := get_wet_dirt_touching_plant(current)
						if my_dirt != current:
							image.set_pixelv(my_dirt, dirt)
							set_pixel_update(my_dirt, true)
							update_neighbors8(my_dirt)
							# remove set the wet dirt in the network to normal dirt
							image.set_pixelv(new_guy, plant)
							plant_data.next = new_guy
							plant_data.plant_height += 1
							plant_data.state_start_time = Time.get_ticks_msec()
							plant_data.growth_this_stage += 1
							plant_data.hurt_times = max(plant_data.hurt_times - 0.5, 0)
							update_neighbors8(new_guy)
						else:
							plant_data.hurt_times += 1
							plant_data.state_start_time = Time.get_ticks_msec()
							if plant_data.hurt_times > 5:
								kill_plant(current)
				if plant_data.plant_height > int(plant_data.leaves * .5) + 2:
					plant_data.state += 1
					plant_data.state_start_time = Time.get_ticks_msec()
					plant_data.growth_this_stage = 0
					plant_data.leaf_growth_this_stage = 0
			3:
				if Time.get_ticks_msec() - plant_data.state_start_time > 2000:
					# get some wet dirt
					var my_dirt := get_wet_dirt_touching_plant(current)
					var new_guy := get_first_available_leaf_spot(current)
					if plant_data.leaf_growth_this_stage > 0:
						new_guy = plant_data.leaf_to_grow

					if my_dirt != current and new_guy != current:
						# consume the water
						image.set_pixelv(my_dirt, dirt)
						set_pixel_update(my_dirt, true)
						update_neighbors8(my_dirt)
						# from the root go up and find the nearest pixel that can grow a leaf to the or right with empty pixel beneatht the leaf
						
						image.set_pixelv(new_guy, leaf)
						plant_data.state_start_time = Time.get_ticks_msec()
						plant_data.growth_this_stage += 1
						plant_data.leaf_growth_this_stage += 1
						plant_data.leaves += 1
						plant_data.hurt_times = max(plant_data.hurt_times - 0.5, 0)
						update_neighbors8(new_guy)
						
						if pixel_in(new_guy + Vector2i.LEFT, [empty]):
							plant_data.leaf_to_grow = new_guy + Vector2i.LEFT
						elif pixel_in(new_guy + Vector2i.RIGHT, [empty]):
							plant_data.leaf_to_grow = new_guy + Vector2i.RIGHT
						else:
							plant_data.leaf_to_grow = get_first_available_leaf_spot(current)
					else:
						# failed growth
						plant_data.hurt_times += 1
						plant_data.state_start_time = Time.get_ticks_msec()
						if plant_data.hurt_times > 7:
							kill_plant(current)
				if plant_data.growth_this_stage > 1:
					plant_data.state = 2
					plant_data.state_start_time = Time.get_ticks_msec()
					plant_data.growth_this_stage = 0
					plant_data.leaf_growth_this_stage += 1
					
		plants[current] = plant_data
	
	plants_alive += 1
	set_pixel_update(current, true)

#:dying plant
func _update_dying_plant(current: Vector2i) -> void:
	if randf() < 0.001:
		if randf() < 0.7:
			image.set_pixelv(current, empty)
		else:
			image.set_pixelv(current, dirt)
		update_neighbors8(current)
	for v in down3:
		if !pixel_in(v, [empty, water]): continue
		swap_pixels(current, v)
		break
	set_pixel_update(current, true)


func kill_plant(current: Vector2i) -> void:
	for px in get_plant_pixels(current):
		image.set_pixelv(px, dying_plant)
		update_neighbors8(px)
		plants.erase(current)
