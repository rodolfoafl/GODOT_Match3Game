extends Node2D

var ice_pieces = []
var width = 8
var height = 10
var ice = preload("res://Scenes/IceObstacle.tscn")

signal break_ice
export (String) var value

func _ready():
	pass

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

func _on_Grid_create_ice(grid_position):
	if(ice_pieces.size() == 0):
		ice_pieces = make_2d_array()
	var current = ice.instance()
	add_child(current)
	current.position = Vector2(grid_position.x * 64 + 64, -grid_position.y * 64 + 800)
	ice_pieces[grid_position.x][grid_position.y] = current


func _on_Grid_damage_ice(grid_position):
	if(ice_pieces.size() != 0):
		var ice_obstacle = ice_pieces[grid_position.x][grid_position.y]	
		if(ice_obstacle != null):
			ice_obstacle.take_damage(1)
			if(ice_obstacle.health <= 0):
				ice_pieces[grid_position.x][grid_position.y].queue_free()
				ice_pieces[grid_position.x][grid_position.y] = null
				emit_signal("break_ice", value)
