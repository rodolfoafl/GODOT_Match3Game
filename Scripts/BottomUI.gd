extends TextureRect

signal pause_game

func _on_PauseButton_pressed():
	emit_signal("pause_game")
	get_tree().paused = true