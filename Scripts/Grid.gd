extends Node2D

enum {wait, move}
var state

export (int) var width
export (int) var height

export (int) var x_start
export (int) var y_start

export (int) var offset
export (int) var y_offset

export (PoolVector2Array) var empty_spaces
export (PoolVector2Array) var ice_spaces
export (PoolVector2Array) var lock_spaces
export (PoolVector2Array) var concrete_spaces

signal damage_ice
signal create_ice
signal damage_lock
signal create_lock
signal damage_concrete
signal create_concrete

var possible_pieces = [
	preload("res://Scenes/BluePiece.tscn"),
	preload("res://Scenes/GreenPiece.tscn"),
	preload("res://Scenes/YellowPiece.tscn"),
	preload("res://Scenes/LightGreenPiece.tscn"),
	preload("res://Scenes/OrangePiece.tscn"),
	preload("res://Scenes/PinkPiece.tscn")
]
var all_pieces = []

var piece_one = null
var piece_two = null
var last_place = Vector2(0, 0)
var last_direction = Vector2(0, 0)
var move_checked = false

var first_touch = Vector2(0, 0)
var last_touch = Vector2(0, 0)
var controlling = false

func _ready():
	state = move
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()
	spawn_ice_obstacles()
	spawn_lock_obstacles()
	spawn_concrete_obstacles()
	
func _process(delta):
	if(state == move):
		touch_input()
	
func spawn_ice_obstacles():
	for i in ice_spaces.size():
		emit_signal("create_ice", ice_spaces[i])
		
func spawn_lock_obstacles():
	for i in lock_spaces.size():
		emit_signal("create_lock", lock_spaces[i])
		
func spawn_concrete_obstacles():
	for i in concrete_spaces.size():
		emit_signal("create_concrete", concrete_spaces[i])
		
func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array
	
func restricted_fill(place):
	if(is_in_array(empty_spaces, place)):
		return true
	if(is_in_array(concrete_spaces, place)):
		return true	
	return false

func restricted_move(place):
	if(is_in_array(lock_spaces, place)):
		return true
	return false

func is_in_array(array, item):
	for i in array.size():
		if(array[i] == item):
			return true
	return false

func spawn_pieces():
	for i in width:
		for j in height:
			if(!restricted_fill(Vector2(i, j))):					
				if(is_piece_null(i, j)):			
					var rand = floor(rand_range(0, possible_pieces.size()))
					var piece = possible_pieces[rand].instance()
					var loops = 0
					while(match_at(i, j, piece.color) && loops < 100):
						rand = floor(rand_range(0, possible_pieces.size()))
						loops += 1
						piece = possible_pieces[rand].instance()			
					
					add_child(piece)
					piece.position = grid_to_pixel(i, j + y_offset)
					piece.move(grid_to_pixel(i, j))
					all_pieces[i][j] = piece
	
	after_refill()
	
func grid_to_pixel(column, row):	
	var new_x = x_start + offset * column
	var new_y = y_start - offset * row
	return Vector2(new_x, new_y)
	
func match_at(column, row, color):
	var i = column
	var j = row
	
	if(i > 1):
		if(!is_piece_null(i - 1, j) && !is_piece_null(i - 2, j)):
			if(all_pieces[i - 1][j].color == color && all_pieces[i - 2][j].color == color):
				return true
	if(j > 1):
		if(!is_piece_null(i, j - 1) && !is_piece_null(i, j - 2)):
			if(all_pieces[i][j - 1].color == color && all_pieces[i][j - 2].color == color):
				return true	
		
func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)

func touch_input():
	if(Input.is_action_just_pressed("ui_touch")):
		if(is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y))):
			first_touch = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			controlling = true
	if(Input.is_action_just_released("ui_touch")):
		if(is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)) && controlling):
			controlling = false
			last_touch = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			touch_difference(first_touch, last_touch)

func swap_pieces(column, row, direction):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	
	if(first_piece != null && other_piece != null):	
		if(!restricted_move(Vector2(column, row)) && !restricted_move(Vector2(column, row) + direction)):
			initialize_swap_pieces(first_piece, other_piece, Vector2(column, row), direction)
			state = wait
			all_pieces[column][row] = other_piece
			all_pieces[column + direction.x][row + direction.y] = first_piece
			first_piece.move(grid_to_pixel(column + direction.x, row +direction.y))
			other_piece.move(grid_to_pixel(column, row))
			if(!move_checked):
				find_matches()
				
func initialize_swap_pieces(first_piece, second_piece, place, direction):
	piece_one = first_piece
	piece_two = second_piece
	last_place = place
	last_direction = direction

func swap_back():
	if(piece_one != null && piece_two != null):
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = move
	move_checked = false

func after_refill():
	for i in width:
		for j in height:
			if(!is_piece_null(i, j)):
				if(match_at(i,j, all_pieces[i][j].color)):
					find_matches()
					return
	move_checked = false
	state = move
	
func touch_difference(first_pos_grid, last_pos_grid):
	var difference = last_pos_grid - first_pos_grid
	if(abs(difference.x) > abs(difference.y)):
		if(difference.x > 0):
			swap_pieces(first_pos_grid.x, first_pos_grid.y, Vector2(1, 0))
		elif(difference.x < 0):
			swap_pieces(first_pos_grid.x, first_pos_grid.y, Vector2(-1, 0))
	elif(abs(difference.y) > abs(difference.x)):
		if(difference.y > 0):
			swap_pieces(first_pos_grid.x, first_pos_grid.y, Vector2(0, 1))
		elif(difference.y < 0):
			swap_pieces(first_pos_grid.x, first_pos_grid.y, Vector2(0, -1))

func is_in_grid(grid_position):
	if(grid_position.x >= 0 && grid_position.x < width):
		if(grid_position.y >= 0 && grid_position.y < height):
			return true
	return false	

func find_matches():
	for i in width:
		for j in height:
			if(!is_piece_null(i, j)):
				var current_color = all_pieces[i][j].color
				if(i > 0 && i < width - 1):
					if(!is_piece_null(i - 1, j) && !is_piece_null(i + 1, j)):
						if(all_pieces[i - 1][j].color == current_color && all_pieces[i + 1][j].color == current_color):
							match_in_axis(i, j, all_pieces, "h")
#							match_and_dim(all_pieces[i - 1][j])
#							match_and_dim(all_pieces[i][j])
#							match_and_dim(all_pieces[i + 1][j])
				if(j > 0 && j < height - 1):
					if(!is_piece_null(i, j - 1) && !is_piece_null(i, j + 1)):
						if(all_pieces[i][j - 1].color == current_color && all_pieces[i][j + 1].color == current_color):
							match_in_axis(i, j, all_pieces, "v")
#							match_and_dim(all_pieces[i][j - 1])
#							match_and_dim(all_pieces[i][j])
#							match_and_dim(all_pieces[i][j + 1])
						
	get_parent().get_node("DestroyTimer").start()

func match_in_axis(column, row, array, axis):
	if(axis == "v"):
		for i in range(row - 1, row + 2):
			match_and_dim(array[column][i])
	if(axis == "h"):
		for i in range(column - 1, column + 2):
			match_and_dim(array[i][row])

func is_piece_null(column, row):
	if(all_pieces[column][row] == null):
		return true
	return false

func match_and_dim(item):
	item.matched = true
	item.dim()

func destroy_matched():
	var was_matched = false	
	for i in width:
		for j in height:
			if(!is_piece_null(i, j)):
				if(all_pieces[i][j].matched):
					damage_special(i, j)
					was_matched = true
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null
	move_checked = true
	if(was_matched):
		get_parent().get_node("CollapseTimer").start()
	else:
		swap_back()

func damage_special(column, row):
	emit_signal("damage_ice", Vector2(column, row))
	emit_signal("damage_lock", Vector2(column, row))
	check_concrete(column, row)

func collapse_columns():
	for i in width:
		for j in height:
			if(is_piece_null(i, j) && !restricted_fill(Vector2(i, j))):
				for k in range(j + 1, height):
					if(!is_piece_null(i, k) && !restricted_move(Vector2(i, k))):
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("RefillTimer").start()

func check_concrete(column, row):
	if(column < width - 1):
		emit_signal("damage_concrete", Vector2(column + 1, row))
	if(column > 0):
		emit_signal("damage_concrete", Vector2(column - 1, row))	
	if(row < height - 1):
		emit_signal("damage_concrete", Vector2(column, row + 1))
	if(row > 0):
		emit_signal("damage_concrete", Vector2(column, row - 1))
			

func remove_from_array(array, item):
	for i in range(array.size() -1, -1, -1):
		if(array[i] == item):
			array.remove(i)
	return array
	
func _on_DestroyTimer_timeout():
	destroy_matched()

func _on_CollapseTimer_timeout():
	collapse_columns()

func _on_RefillTimer_timeout():
	spawn_pieces()

func _on_LockHolder_remove_lock(place):
	lock_spaces = remove_from_array(lock_spaces, place)

func _on_ConcreteHolder_remove_concrete(place):
	concrete_spaces = remove_from_array(concrete_spaces, place)
