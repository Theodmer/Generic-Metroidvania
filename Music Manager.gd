extends Node2D

@onready var night_ambient_1 = $"Night Ambient 1"
@onready var night_ambient_2 = $"Night Ambient 2"
@onready var night_ambient_3 = $"Night Ambient 3"

var night_ambients = []

func _ready():
	night_ambients.append(night_ambient_1)
	night_ambients.append(night_ambient_2)
	night_ambients.append(night_ambient_3)
	choose_next_music()


func choose_next_music():
	var next_in_line = night_ambients[randi_range(0, 2)]
	await get_tree().create_timer(randf_range(3, 15)).timeout
	next_in_line.play()


func _on_night_ambient_1_finished():
	choose_next_music()

func _on_night_ambient_2_finished():
	choose_next_music()

func _on_night_ambient_3_finished():
	choose_next_music()
