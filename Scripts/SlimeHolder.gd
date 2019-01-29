extends Node2D

signal remove_slime

var slime_pieces = []
var width = 8
var height = 10
var slime = preload("res://Scenes/SlimeObstacle.tscn")

func _ready():
	pass

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

func _on_Grid_create_slime(grid_position):
	if(slime_pieces.size() == 0):
		slime_pieces = make_2d_array()
	var current = slime.instance()
	add_child(current)
	
	current.position = Vector2(grid_position.x * 64 + 64, -grid_position.y * 64 + 800)
	slime_pieces[grid_position.x][grid_position.y] = current


func _on_Grid_damage_slime(grid_position):
	if(slime_pieces.size() != 0):	
		var slime_obstacle = slime_pieces[grid_position.x][grid_position.y]	
		if(slime_obstacle != null):
			slime_obstacle.take_damage(1)
			if(slime_obstacle.health <= 0):
				slime_pieces[grid_position.x][grid_position.y].queue_free()
				slime_pieces[grid_position.x][grid_position.y] = null
				emit_signal("remove_slime", grid_position)
