extends Node2D

const drop_acc_sq: float = 10000 ** 2

var spigot_on: bool = false
var holding: Area2D = null
var holding_velocity: Vector2
var holding_drop_spot: Area2D = null
var tilted: bool = false

@onready var sim: PixelSimulation = $PixelSimulation2
@onready var cursor: Area2D = $Cursor
@onready var spigot: Area2D = $Spigot
@onready var seeds: Area2D = $Seeds
@onready var watering_can: Area2D = $WateringCan

func _process(delta: float) -> void:
	if holding:
		var old_pos := holding.global_position
		var new_pos := get_global_mouse_position()
		holding.global_position = new_pos
		var old_vel := holding_velocity
		var new_vel := (new_pos - old_pos) / delta
		holding_velocity = new_vel
		var holding_acceleration := (new_vel - old_vel) / delta
		match holding:
			seeds:
				var should_drop := holding_acceleration.length_squared() > drop_acc_sq and tilted
				if should_drop:
					var pixel := sim.global_to_pixel(get_global_mouse_position())
					sim.spawn_pixel(pixel, sim.pumpkin_seed)
			watering_can:
				var should_drop := holding_acceleration.length_squared() > drop_acc_sq and tilted
				if should_drop:
					var pixel := sim.global_to_pixel(get_global_mouse_position())
					sim.spawn_pixel(pixel, sim.dirt)
		
		if cursor.overlaps_area(holding_drop_spot):
			holding_drop_spot.scale = Vector2(1.5, 1.5)
		else:
			holding_drop_spot.scale = Vector2.ONE
			
		
		if Input.is_action_just_pressed("click"):
			if cursor.overlaps_area(holding_drop_spot):
				holding_drop_spot.hide()
				tilted = false
				holding.rotation_degrees = 0
				holding.position = holding_drop_spot.position
				holding = null
			else:
				tilted = !tilted
				holding.rotation_degrees = -45 if tilted else 0
				
	else:
		# try to interact with something
		

		if Input.is_action_just_pressed("click"):
			if cursor.overlaps_area(spigot):
				spigot_on = !spigot_on
			elif cursor.overlaps_area(seeds):
				holding = seeds
				holding_drop_spot = $SeedDropSpot
			elif cursor.overlaps_area(watering_can):
				holding = watering_can
				holding_drop_spot = $CanDropSpot
				
			if holding:
				holding_drop_spot.show()
				
	
	if spigot_on:
		var pixel := sim.global_to_pixel($Spigot/Spawn.global_position)
		sim.spawn_pixel(pixel, sim.water)
		
	cursor.global_position = get_global_mouse_position()
