extends ProgressBar

@onready var damage_bar = $"Damage Bar"
@onready var timer = $Timer

var health = 0: set = _set_health


func _set_health(new_hp):
	var prev_hp = health
	health = min(max_value, new_hp)
	value = health
	
	if health < prev_hp:
		timer.start()
	else:
		damage_bar.value = health


func init_health(_health):
	health = _health
	max_value = health
	value = health
	
	damage_bar.max_value = health
	damage_bar.value = health

func _on_timer_timeout():
	damage_bar.value = health
