extends Area2D

@export var insta_kill := false
@export var damage_dealt: int = 10
@export var knockback_strength: float = 0


func _on_body_entered(body):
	if !(body is CharacterBody2D):
		return
	
	if insta_kill:
		body.die()
	else:
		print("Dealt ", damage_dealt, " damage to ", body)
		var knockback_dir = Vector2(body.position - position).normalized()
		if !body.invulnerable:
			body.take_damage(damage_dealt, knockback_dir, knockback_strength)
