extends Node

var level_info = {}
var default_level_info = {
	1:{
		"unlocked": true,
		"high_score": 0,
		"stars_unlocked": 0
	}
}

onready var path = "user://save.dat"

func _ready():
	level_info = load_data()

func save_data():
	var file = File.new()
	var err = file.open(path, File.WRITE)
	
	if err != OK:
		print("An error occured while trying to save the data file!")
		return
		
	file.store_var(level_info)
	file.close()

func load_data():
	var file = File.new()
	var err = file.open(path, File.READ)
	
	if err != OK:
		print("An error occured while trying to load the data file!")
		return default_level_info
	var read = {}
	read = file.get_var()
	return read
