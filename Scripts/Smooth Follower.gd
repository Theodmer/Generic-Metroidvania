extends Node2D

@export var object_to_follow: Node2D
@export var follow_speed: float = 4.0


func _physics_process(delta):
	position = position.lerp(object_to_follow.position, delta * follow_speed)
