extends TextureRect

signal pause_game
signal booster_pressed

func _on_PauseButton_pressed():
	emit_signal("pause_game")
	get_tree().paused = true

func _on_Booster1Button_pressed():
	emit_signal("booster_pressed", BoosterInfo.booster_info[1])


func _on_Booster2Button_pressed():
	emit_signal("booster_pressed", BoosterInfo.booster_info[2])


func _on_Booster3Button_pressed():
	emit_signal("booster_pressed", BoosterInfo.booster_info[3])
