extends Node2D

export (int) var health

func _ready():
	pass
	
func take_damage(damage):
	health -= damage
