extends Area2D

@onready var audio = $AudioStreamPlayer2D
@onready var timer = $Timer

var upgraded := false


func _ready():
	upgraded = GameManager.upgraded
	if upgraded:
		$AudioStreamPlayer2D.playing = false
		$CPUParticles2D.emitting = false
		timer.stop()

func _on_body_entered(body):
	if upgraded:
		return
	
	upgraded = true
	body.upgrade_sword()
	$CPUParticles2D.emitting = false
	timer.stop()


func _on_timer_timeout():
	audio.play()
