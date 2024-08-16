class_name LivingBeing
extends CharacterBody2D

@export var max_hp: int = 100
@export var current_hp: int = 100
@export var death_animation: AnimatedSprite2D
@export var damage_taken_sfx: AudioStreamPlayer2D

var knockback: Vector2 = Vector2.ZERO
var being_knocked_back := false
var invulnerable := false

var hp: int:
	get:
		return current_hp
	set(new_hp):
		current_hp = clampi(new_hp, 0, max_hp)
		if current_hp == 0:
			die()


func take_damage(damage_taken: int, knockback_direction: Vector2, knockback_strength: float):
	hp -= damage_taken
	if damage_taken_sfx != null:
		damage_taken_sfx.play() 
	take_knockback(knockback_direction, knockback_strength)


func take_knockback(knockback_direction: Vector2, knockback_strength: float):
	knockback = knockback_direction * knockback_strength
	
	being_knocked_back = true
	await get_tree().create_timer(0.1).timeout
	being_knocked_back = false
	
	knockback = Vector2.ZERO


func die():
	#death_animation.play("Death")
	pass
