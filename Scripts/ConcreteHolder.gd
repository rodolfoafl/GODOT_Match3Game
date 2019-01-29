extends Node2D

signal remove_concrete

var concrete_pieces = []
var width = 8
var height = 10
var concrete = preload("res://Scenes/ConcreteObstacle.tscn")

func _ready():
	pass

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

func _on_Grid_create_concrete(grid_position):
	if(concrete_pieces.size() == 0):
		concrete_pieces = make_2d_array()
	var current = concrete.instance()
	add_child(current)
	
	current.position = Vector2(grid_position.x * 64 + 64, -grid_position.y * 64 + 800)
	concrete_pieces[grid_position.x][grid_position.y] = current


func _on_Grid_damage_concrete(grid_position):
	if(concrete_pieces.size() != 0):
		var concrete_obstacle = concrete_pieces[grid_position.x][grid_position.y]	
		if(concrete_obstacle != null):
			concrete_obstacle.take_damage(1)
			if(concrete_obstacle.health <= 0):
				concrete_pieces[grid_position.x][grid_position.y].queue_free()
				concrete_pieces[grid_position.x][grid_position.y] = null
				emit_signal("remove_concrete", grid_position)
