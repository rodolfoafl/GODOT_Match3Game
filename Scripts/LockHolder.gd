extends Node2D

signal remove_lock

var lock_pieces = []
var width = 8
var height = 10
var lock = preload("res://Scenes/LockObstacle.tscn")

func _ready():
	pass

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

func _on_Grid_create_lock(grid_position):
	if(lock_pieces.size() == 0):
		lock_pieces = make_2d_array()
	var current = lock.instance()
	add_child(current)
	
	current.position = Vector2(grid_position.x * 64 + 64, -grid_position.y * 64 + 800)
	lock_pieces[grid_position.x][grid_position.y] = current


func _on_Grid_damage_lock(grid_position):
	if(lock_pieces.size() != 0):
		var lock_obstacle = lock_pieces[grid_position.x][grid_position.y]	
		if(lock_obstacle != null):
			lock_obstacle.take_damage(1)
			if(lock_obstacle.health <= 0):
				lock_pieces[grid_position.x][grid_position.y].queue_free()
				lock_pieces[grid_position.x][grid_position.y] = null
				emit_signal("remove_lock", grid_position)
