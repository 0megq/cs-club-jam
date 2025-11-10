extends Node2D

var spigot_on: bool = false
@onready var sim: PixelSimulation = $PixelSimulation2
@onready var cursor: Area2D = $Cursor

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("click") and $Spigot.overlaps_area(cursor):
		spigot_on = !spigot_on
		
	if spigot_on:
		var pixel := sim.global_to_pixel($Spigot/Spawn.global_position)
		sim.spawn_pixel(pixel, sim.water)
		
	cursor.global_position = get_global_mouse_position()
