extends Node2D

export (String) var color
export (float) var tween_speed

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
