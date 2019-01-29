extends Node2D

export (String) var color
export (Texture) var row_bomb_texture
export (Texture) var column_bomb_texture
export (Texture) var adjacent_bomb_texture

export (float) var tween_speed

var is_row_bomb = false
var is_column_bomb = false
var is_adjacent_bomb = false

var move_tween
var matched = false

func _ready():
	move_tween = $MoveTween
	
func move(target):
	move_tween.interpolate_property(self, "position", position, target, tween_speed, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	move_tween.start()
	
func dim():
	var sprite = $Sprite
	sprite.modulate = Color(1, 1, 1, .5)
	
func create_column_bomb():
	is_column_bomb = true
	$Sprite.texture = column_bomb_texture
	$Sprite.modulate = Color(1, 1, 1, 1)

func create_row_bomb():
	is_row_bomb = true
	$Sprite.texture = row_bomb_texture
	$Sprite.modulate = Color(1, 1, 1, 1)

func create_adjacent_bomb():
	is_adjacent_bomb = true
	$Sprite.texture = adjacent_bomb_texture
	$Sprite.modulate = Color(1, 1, 1, 1)
