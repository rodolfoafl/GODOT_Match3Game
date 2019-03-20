extends Node2D

onready var sprite = $Sprite
onready var size_tween = $SizeTween
onready var color_tween = $ColorTween

func _ready():
	setup(sprite.texture)
	
func setup(new_sprite):
	sprite.texture = new_sprite
	activate_size_tween()
	activate_color_tween()

func activate_size_tween():
	size_tween.interpolate_property(sprite, "scale", Vector2(0.5, 0.5), Vector2(.75, .75), 0.75, Tween.TRANS_SINE, Tween.EASE_OUT)
	size_tween.start()
	
func activate_color_tween():
	color_tween.interpolate_property(sprite, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0.2), 0.75, Tween.TRANS_SINE, Tween.EASE_OUT)
	color_tween.start()

func _on_SizeTween_tween_completed(object, key):
	activate_size_tween()

func _on_ColorTween_tween_completed(object, key):
	activate_color_tween()
