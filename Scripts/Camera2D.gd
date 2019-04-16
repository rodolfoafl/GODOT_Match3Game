extends Camera2D

func move_camera(placement):
	offset = placement

func _on_Grid_place_camera(placement):
	move_camera(placement)