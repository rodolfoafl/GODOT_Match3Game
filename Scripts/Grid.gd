extends Node2D

enum {wait, move}
enum {column_bomb, row_bomb, adjacent_bomb, color_bomb}
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
export (PoolVector2Array) var slime_spaces

export (int) var current_counter_value
export (bool) var is_moves 

signal damage_ice
signal create_ice
signal damage_lock
signal create_lock
signal damage_concrete
signal create_concrete
signal damage_slime
signal create_slime

signal update_counter

signal game_over

var color_bomb_used = false

var possible_pieces = [
	preload("res://Scenes/BluePiece.tscn"),
	preload("res://Scenes/GreenPiece.tscn"),
	preload("res://Scenes/YellowPiece.tscn"),
	preload("res://Scenes/LightGreenPiece.tscn"),
	preload("res://Scenes/OrangePiece.tscn"),
	#preload("res://Scenes/PinkPiece.tscn")
]
var all_pieces = []
var current_matches = []

var animated_effect = preload("res://Scenes/ExplosionEffect.tscn")
var particle_effect = preload("res://Scenes/Particle.tscn")

var piece_one = null
var piece_two = null
var last_place = Vector2(0, 0)
var last_direction = Vector2(0, 0)
var move_checked = false

var damaged_slime = false
var first_round = true

var first_touch = Vector2(0, 0)
var last_touch = Vector2(0, 0)
var controlling = false

signal update_score
export (int) var piece_value
var streak = 1

var audio_player

func _ready():
	state = move
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()
	spawn_ice_obstacles()
	spawn_lock_obstacles()
	spawn_concrete_obstacles()
	spawn_slime_obstacles()	
	
	emit_signal("update_counter", current_counter_value)
	if(!is_moves):
		$Timer.start()
	
	audio_player = get_parent().get_node("AudioPlayer")
	audio_player.stream = load("res://SFX/piece_matched.ogg")
	
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
		
func spawn_slime_obstacles():
	for i in slime_spaces.size():
		emit_signal("create_slime", slime_spaces[i])
		
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
	if(is_in_array(slime_spaces, place)):
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
			if(is_color_bomb(first_piece, other_piece)):
				if(first_piece.color == "Color" && other_piece.color == "Color"):
					clear_board()			
				if(first_piece.color == "Color"):
					match_color(other_piece)
					match_and_dim(first_piece)
					add_to_array(Vector2(column, row), current_matches)
				else:
					match_color(first_piece)
					match_and_dim(other_piece)
					add_to_array(Vector2(column + direction.x, row + direction.y), current_matches)
			initialize_swap_pieces(first_piece, other_piece, Vector2(column, row), direction)
			state = wait
			all_pieces[column][row] = other_piece
			all_pieces[column + direction.x][row + direction.y] = first_piece
			first_piece.move(grid_to_pixel(column + direction.x, row +direction.y))
			other_piece.move(grid_to_pixel(column, row))
			if(!move_checked):
				find_matches()

func is_color_bomb(piece_one, piece_two):
	if(piece_one.color == "Color" || piece_two.color == "Color"):
		color_bomb_used = true
		return true
	return false
				
func match_color(piece):
	for i in width:
		for j in height:
			if(all_pieces[i][j] != null):
				if(all_pieces[i][j].color == piece.color):
					match_and_dim(all_pieces[i][j])
					add_to_array(Vector2(i, j), all_pieces)
				
func clear_board():
	for i in width:
		for j in height:
			if(all_pieces[i][j] != null):
				match_and_dim(all_pieces[i][j])
				add_to_array(Vector2(i, j), all_pieces)
				
				
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

func refill_columns():
	streak += 1
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

func after_refill():	
	for i in width:
		for j in height:
			if(!is_piece_null(i, j)):
				if(match_at(i,j, all_pieces[i][j].color)):
					find_matches()
					return
					
	if(!damaged_slime && !first_round):
		generate_slime()
	if(is_deadlocked()):
		print("Deadlocked!")
		#shuffle_board()	
		
	first_round = false
	damaged_slime = false
	move_checked = false	
	color_bomb_used = false
	state = move
	streak = 1	
	
	if(is_moves):
		_on_Timer_timeout()

	
func generate_slime():
	if(slime_spaces.size() > 0):
		var slime_made = false
		var tracker = 0
		while(!slime_made && tracker < 100):
			var random_num = floor(rand_range(0, slime_spaces.size()))
			var current_x = slime_spaces[random_num].x
			var current_y = slime_spaces[random_num].y
			var neighbor = find_normal_neighbor(current_x, current_y)
			if(neighbor != null):
				all_pieces[neighbor.x][neighbor.y].queue_free()
				all_pieces[neighbor.x][neighbor.y] = null
				slime_spaces.append(Vector2(neighbor.x, neighbor.y))
				emit_signal("create_slime", Vector2(neighbor.x, neighbor.y))
				slime_made = true
			tracker += 1
	pass

func find_normal_neighbor(column, row):
	var possible_neighbor = []
	
	if(is_in_grid(Vector2(column + 1, row))):
		if(all_pieces[column + 1][row] != null):
			possible_neighbor.append(Vector2(column + 1, row))
	if(is_in_grid(Vector2(column - 1, row))):
		if(all_pieces[column - 1][row] != null):
			possible_neighbor.append(Vector2(column - 1, row))			
	if(is_in_grid(Vector2(column, row + 1))):
		if(all_pieces[column][row + 1] != null):
			possible_neighbor.append(Vector2(column, row + 1))
	if(is_in_grid(Vector2(column, row - 1))):
		if(all_pieces[column][row - 1] != null):
			possible_neighbor.append(Vector2(column, row - 1))
	
	if(possible_neighbor.size() > 0):		
		var rand = floor(rand_range(0, possible_neighbor.size()))
		if(possible_neighbor[rand] != null):
			return possible_neighbor[rand]
	return null
	
func match_all_in_column(column):
	for i in height:
		if(all_pieces[column][i] != null):
			if(all_pieces[column][i].is_row_bomb):
				match_all_in_row(i)
			if(all_pieces[column][i].is_adjacent_bomb):
				find_adjacent_pieces(column, i)
			all_pieces[column][i].matched = true
	
func match_all_in_row(row):
	for i in width:
		if(all_pieces[i][row] != null):
			if(all_pieces[i][row].is_column_bomb):
				match_all_in_column(i)
			if(all_pieces[i][row].is_adjacent_bomb):
				find_adjacent_pieces(i, row)
			all_pieces[i][row].matched = true
			
func find_adjacent_pieces(column, row):
	for i in range(-1, 2):
		for j in range(-1, 2):
			if(is_in_grid(Vector2(column + i, row + j))):
				if(all_pieces[column + i][row + j]!= null):
					if(all_pieces[column + i][row + j].is_column_bomb):
						match_all_in_column(column + i)
					if(all_pieces[column + i][row + j].is_row_bomb):
						match_all_in_row(row + j)
					all_pieces[column + i][row + j].matched = true

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
			#if(!is_piece_null(i, j)):
			var current_color = all_pieces[i][j].color
			if(i > 0 && i < width - 1):
				if(!is_piece_null(i - 1, j) && !is_piece_null(i + 1, j)):
					if(all_pieces[i - 1][j].color == current_color && all_pieces[i + 1][j].color == current_color):
						match_in_axis(i, j, all_pieces, "h")
			if(j > 0 && j < height - 1):
				if(!is_piece_null(i, j - 1) && !is_piece_null(i, j + 1)):
					if(all_pieces[i][j - 1].color == current_color && all_pieces[i][j + 1].color == current_color):
						match_in_axis(i, j, all_pieces, "v")
											
	get_bombed_pieces()
	get_parent().get_node("DestroyTimer").start()
	
func get_bombed_pieces():
	for i in width:
		for j in height:
			if(all_pieces[i][j] != null):
				if(all_pieces[i][j].matched):
					if(all_pieces[i][j].is_column_bomb):
						match_all_in_column(i)
					elif(all_pieces[i][j].is_row_bomb):
						match_all_in_row(j)
					elif(all_pieces[i][j].is_adjacent_bomb):
						find_adjacent_pieces(i, j)

func match_in_axis(column, row, array, axis):
	if(axis == "v"):
		for i in range(row - 1, row + 2):
			match_and_dim(array[column][i])
			add_to_array(Vector2(column, i), current_matches)
	if(axis == "h"):
		for i in range(column - 1, column + 2):
			match_and_dim(array[i][row])
			add_to_array(Vector2(i, row), current_matches)

func is_piece_null(column, row):
	if(all_pieces[column][row] == null):
		return true
	return false

func match_and_dim(item):
	item.matched = true
	item.dim()

func find_bombs():
	for i in current_matches.size():
		var column_matched = 0
		var row_matched = 0
		var current_column = current_matches[i].x
		var current_row = current_matches[i].y
		var current_color = all_pieces[current_column][current_row].color
		for j in current_matches.size():
			var this_column = current_matches[j].x
			var this_row = current_matches[j].y
			var this_color = all_pieces[this_column][this_row].color
			if(this_column == current_column && this_color == current_color):
				column_matched += 1
			if(this_row == current_row && this_color == current_color):
				row_matched += 1
				
		if(column_matched == 4):
			make_bomb(row_bomb, current_color)
		if(row_matched == 4):
			make_bomb(column_bomb, current_color)
		if(column_matched == 3 && row_matched == 3):
			make_bomb(adjacent_bomb, current_color)
		if(column_matched == 5 || row_matched == 5):
			make_bomb(color_bomb, current_color)

func make_bomb(bomb_type, color):
	# CURRENTLY, ONLY WHEN THE PLAYER SWAP PIECES BOMBS ARE CREATED.
	# IDEALLY, IT SHOULD ALSO HAPPEN WHEN THE GRIND REFILLS ITSELF.
	for i in current_matches.size():
		var current_column = current_matches[i].x
		var current_row = current_matches[i].y
		if(all_pieces[current_column][current_row] == piece_one && piece_one.color == color):
			piece_one.matched = false
			change_bomb(bomb_type, piece_one)
		if(all_pieces[current_column][current_row] == piece_two && piece_two.color == color):
			piece_two.matched = false
			change_bomb(bomb_type, piece_two)
			
func change_bomb(bomb_type, piece):
	match(bomb_type):
		column_bomb:
			piece.create_column_bomb()
		row_bomb:
			piece.create_row_bomb()
		adjacent_bomb:
			piece.create_adjacent_bomb()
		color_bomb:
			piece.create_color_bomb()
	
func destroy_matched():
	find_bombs()
	var was_matched = false	
	for i in width:
		for j in height:
			if(!is_piece_null(i, j)):
				if(all_pieces[i][j].matched):
					audio_player.play()
					damage_special(i, j)
					was_matched = true
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null
					create_effect(particle_effect, i, j)
					create_effect(animated_effect, i, j)
					emit_signal("update_score", piece_value * streak)
	move_checked = true
	if(was_matched):
		get_parent().get_node("CollapseTimer").start()
	else:
		swap_back()
	current_matches.clear()

func create_effect(effect, column, row):
	var current = effect.instance()
	current.position = grid_to_pixel(column, row)
	add_child(current)

func add_to_array(value, array_to_add):
	if(!array_to_add.has(value)):
		array_to_add.append(value)

func damage_special(column, row):
	emit_signal("damage_ice", Vector2(column, row))
	emit_signal("damage_lock", Vector2(column, row))
	check_concrete(column, row)
	check_slime(column, row)

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
		
func check_slime(column, row):
	if(column < width - 1):
		emit_signal("damage_slime", Vector2(column + 1, row))
	if(column > 0):
		emit_signal("damage_slime", Vector2(column - 1, row))	
	if(row < height - 1):
		emit_signal("damage_slime", Vector2(column, row + 1))
	if(row > 0):
		emit_signal("damage_slime", Vector2(column, row - 1))
			
func remove_from_array(array, item):
	for i in range(array.size() -1, -1, -1):
		if(array[i] == item):
			array.remove(i)
	return array	
	
func switch_pieces(column, row, direction):
	var holder = all_pieces[column + direction.x][row + direction.y]
	all_pieces[column + direction.x][row + direction.y] = all_pieces[column][row]
	all_pieces[column][row] = holder

func is_deadlocked():
	for i in width:
		for j in height:
			if(!is_piece_null(i, j)):
				if(i < width - 1):
					if(switch_and_check(i, j, Vector2(1, 0))):
						return false
				if(j < height - 1):
					if(switch_and_check(i, j, Vector2(0, 1))):
						return false
	return true	
	
func shuffle_board():
	pass
#	var new_grid = []
#
#	for i in width:
#		new_grid.append([])
#		for j in height:
#			if(!is_piece_null(i, j)):
#				new_grid[i].append(all_pieces[i][j])
#
#	for i in width:		
#		for j in height:		
#			var index = floor(rand_range(0, new_grid.size()))		
#			var piece = new_grid[index][j]
#			print("\npiece: " + str(piece))
#
#			piece.position = grid_to_pixel(i, j + y_offset)
#			piece.move(grid_to_pixel(i, j))
#			all_pieces[i][j] = new_grid[index][j]
#			new_grid.remove(piece)
##
#	if(is_deadlocked()):
#		shuffle_board()			
				
func switch_and_check(column, row, direction):
	switch_pieces(column, row, direction)
	if(check_for_matches()):
		switch_pieces(column, row, direction)
		return true
	switch_pieces(column, row, direction)
	return false
	
func check_for_matches():
	for i in width:
		for j in height:
			if(all_pieces[i][j] != null):
				if(i < width - 2):				
					if(all_pieces[i + 1][j] != null && all_pieces[i + 2][j] != null):
						if(all_pieces[i + 1][j].color == all_pieces[i][j].color && all_pieces[i + 2][j].color == all_pieces[i][j].color):
							return true
				if(j < height - 2):
					if(all_pieces[i][j + 1] != null && all_pieces[i][j + 2] != null):
						if(all_pieces[i][j + 1].color == all_pieces[i][j].color && all_pieces[i][j + 2].color == all_pieces[i][j].color):
							return true
	
	return false
	
func _on_DestroyTimer_timeout():
	destroy_matched()

func _on_CollapseTimer_timeout():
	collapse_columns()

func _on_RefillTimer_timeout():
	refill_columns()

func _on_LockHolder_remove_lock(place):
	lock_spaces = remove_from_array(lock_spaces, place)

func _on_ConcreteHolder_remove_concrete(place):
	concrete_spaces = remove_from_array(concrete_spaces, place)
	
func _on_SlimeHolder_remove_slime(place):
	damaged_slime = true
	slime_spaces = remove_from_array(slime_spaces, place)

func _on_Timer_timeout():
	current_counter_value -= 1
	emit_signal("update_counter")
	
	print(current_counter_value)
	if(current_counter_value == 0):
		set_game_over()
		$Timer.stop()
	
func set_game_over():
	print("game over!")
	emit_signal("game_over")
	state = wait
