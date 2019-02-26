extends TextureRect

onready var score_label = $MarginContainer/HBoxContainer/VBoxContainer/ScoreLabel
onready var counter = $MarginContainer/HBoxContainer/Counter
onready var score_bar = $MarginContainer/HBoxContainer/VBoxContainer/TextureProgress
onready var goal_container = $MarginContainer/HBoxContainer/HBoxContainer

export (PackedScene) var goal_prefab

var current_count = 0
var current_score = 0 

func _ready():
	_on_Grid_update_score(current_score)

func _on_Grid_update_score(amount_to_change):
	current_score += amount_to_change
	update_score_bar()
	score_label.text = String(current_score)

func _on_Grid_update_counter(amount_to_change = -1):
	current_count += amount_to_change
	counter.text = String(current_count)
	
func setup_score_bar(max_score):
	score_bar.max_value = max_score

func update_score_bar():
	score_bar.value = current_score
	
func create_goal(new_max, new_texture, new_value):
	var current = goal_prefab.instance()
	goal_container.add_child(current)
	current.set_goal_values(new_max, new_texture, new_value)	
	
func _on_Grid_setup_max_score(max_score):
	setup_score_bar(max_score)


func _on_GoalHolder_create_goal(new_max, new_texture, new_value):
	create_goal(new_max, new_texture, new_value)
	pass # replace with function body


func _on_Grid_check_goal(goal_type):
	for i in goal_container.get_child_count():
		goal_container.get_child(i).update_goal_values(goal_type)
