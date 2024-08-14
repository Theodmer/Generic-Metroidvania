extends LivingBeing

func take_damage(damage_taken: int, knockback_direction: Vector2, knockback_strength: float):
	damage_taken_sfx.pitch_scale = randf_range(0.8, 1.1)
	super(damage_taken, knockback_direction, knockback_strength)
	death_animation.play("Damaged")


func _on_animated_sprite_2d_animation_finished():
	if death_animation.animation == "Damaged":
		death_animation.play("Idle")
