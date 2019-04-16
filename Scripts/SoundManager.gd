extends Node

onready var sound_player = $AudioStreamPlayer2D
onready var music_player

var possible_sounds = [
	preload("res://SFX/piece_matched.ogg")
]

#REMINDER: CHANGE THE "LOOP" SETTING ON IMPORT TAB!
var possible_music = []

func _ready():	
	randomize()
	set_volume()
	play_random_music()

func play_random_music():
	if(possible_music.size() > 0):
		var temp = floor(rand_range(0, possible_music.size()))
		if(music_player != null):
			music_player.stream = load(possible_music[temp])
			music_player.play()
	else:
		print("Possible_music array is empty!")
		
func play_random_sound():
	if(possible_sounds.size() > 0):
		var temp = floor(rand_range(0, possible_sounds.size()))
		if(sound_player != null):
			print("random_sound!")
			sound_player.stream = possible_sounds[temp]
			sound_player.play()
	else:
		print("Possible_sound array is empty!")
		
func play_fixed_sound(sound):
	if(possible_sounds.size() > 0):
		if(sound_player != null):
			print("fixed_sound!")
			sound_player.stream = possible_sounds[sound]
			sound_player.play()
	else:
		print("Possible_sound array is empty!")
		
func set_volume():
	print("here!")
	if(ConfigManager.sound_on):
		if(music_player != null):
			music_player.volume_db = -20
		if(sound_player != null):
			print("sound_on")
			sound_player.volume_db = -15
	else:
		if(music_player != null):
			music_player.volume_db = -80
		if(sound_player != null):
			print("sound_off")
			sound_player.volume_db = -80