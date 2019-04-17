extends Camera2D

onready var screen_kick = $ScreenKick

func move_camera(placement):
	offset = placement

func _on_Grid_place_camera(placement):
	move_camera(placement)
	
func camera_effect():
	screen_kick.interpolate_property(self, "zoom", Vector2(0.95, 0.95), Vector2(1, 1), 0.3, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
	screen_kick.start()

func _on_Grid_camera_effect():
	camera_effect()
