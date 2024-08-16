extends LivingBeing

@export_group("Movement")
@export var run_speed: float = 350.0
@export var jump_velocity: float = -500.0
@export var coyote_time_duration: float = 0.15
@export var dash_velocity: float = 900.0
@export var dash_duration: float = 0.15
@export var pre_dash_duration: float = 0.1
@export var dash_cooldown: float = 0.8

@export_group("Combat")
@export var second_attack_buffered := false
@export var attack_1_damage : float = 10.0
@export var attack_1_knockback : float = 1.0
@export var attack_2_damage : float = 15.0
@export var attack_2_knockback : float = 2.0

@export_group("UI")
@export var healthbar: ProgressBar
@export var attack_1_collision: CollisionShape2D
@export var attack_2_collision: CollisionShape2D

@export_group("SFX")
@export var footstep_delay: float = 0.1
@export var dash_sfx: AudioStreamPlayer2D
@export var jump_sfx: AudioStreamPlayer2D
@export var upgrade_sfx: AudioStreamPlayer2D
@export var footstep_sfx: AudioStreamPlayer2D
@export var damage_dealt_sfx: AudioStreamPlayer2D
@export var footstep_timer: Timer

var direction: int = 0
var facing_right := true
var can_move := true
var is_dashing := false
var can_change_animations := true
var can_dash := true
var can_double_jump := true
var coyote_time := false
var playing_footstep_sfx := false
var dash_buffered := false

var attacking := false
var can_attack := false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum AnimationStates {
	Idle,
	Running,
	Dashing,
	Ascending,
	Descending,
	Upgrading,
	Attack1,
	Attack2,
}
var current_animation_state: AnimationStates = AnimationStates.Idle

@onready var animated_sprite = $Flippables/AnimatedSprite2D

# SCENES
const HIT_PARTICLES = preload("res://Scenes/Combat/hit_particles.tscn")
const ATTACK_1 = preload("res://Scenes/VFX/Attack 1 VFX.tscn")
const ATTACK_2 = preload("res://Scenes/VFX/Attack 2 VFX.tscn")

func _ready():
	can_attack = GameManager.upgraded
	await get_tree().create_timer(0.3).timeout
	healthbar.init_health(max_hp)


func _physics_process(delta):
	handle_grounded()
	apply_gravity(delta)
	
	play_footstep_sfx()
	
	handle_attack_input()
	
	handle_movement(delta)
	handle_animations()

func apply_gravity(delta: float):
	if not is_on_floor() and can_move:
		velocity.y += gravity * delta


func give_velocity():
	if direction and can_move:
		velocity.x = direction * run_speed
	else:
		velocity.x = move_toward(velocity.x, 0, run_speed)
	
	if being_knocked_back:
		velocity = Vector2(knockback.x, knockback.y / 2.0)


func play_footstep_sfx():
	if !direction or !is_on_floor() or !can_move:
		return
	if footstep_timer.time_left > 0:
		return
	footstep_sfx.pitch_scale = randf_range(0.8, 1.2)
	footstep_sfx.play()
	footstep_timer.start()


func handle_grounded():
	if is_on_floor():
		can_double_jump = true


func handle_attack_input():
	if !can_attack:
		return
	
	if Input.is_action_just_pressed("Attack"):
		if (current_animation_state == AnimationStates.Idle or 
					current_animation_state == AnimationStates.Running):
			start_attack_1()
		elif current_animation_state == AnimationStates.Attack1:
			second_attack_buffered = true
		elif !is_on_floor():
			start_attack_2()


func handle_movement(delta: float):
	buffer_dash(0.3)
	
	if !can_move:
		velocity = Vector2.ZERO
		return
		
	handle_movement_input()
	if is_dashing:
		dash(delta)
	elif !is_dashing and can_move:
		give_velocity()
	elif !can_move:
		velocity = Vector2(0,0)
	
	var was_on_floor = is_on_floor()
	move_and_slide()
	if was_on_floor and !is_on_floor():
		start_coyote_timer()
	if !was_on_floor and is_on_floor() and GameManager.upgraded:
		current_animation_state = AnimationStates.Idle
		can_attack = true


func start_coyote_timer():
	coyote_time = true
	await get_tree().create_timer(coyote_time_duration).timeout
	coyote_time = false


func handle_movement_input():
	if !can_move:
		return
	calculate_direction()
	
	jump()
	
	if Input.is_action_just_pressed("Upgrade"):
		upgrade_sword()
	
	
	
	if dash_buffered and can_dash and !is_dashing:
		start_dashing()


func calculate_direction():
	if !can_move:
		return
	var old_direction = direction
	
	direction = Input.get_axis("Left", "Right") * scale.x
	if direction > 0:
		facing_right = true
	elif direction < 0:
		facing_right = false

	if old_direction != 0 and direction == 0:
		current_animation_state = AnimationStates.Idle


func jump():
	if !Input.is_action_just_pressed("Jump"):
		return
		
	if is_on_floor() or coyote_time:
		jump_sfx.pitch_scale = randf_range(0.9, 1.1)
		velocity.y = jump_velocity
		jump_sfx.play()
		coyote_time = false
	elif can_double_jump:
		jump_sfx.pitch_scale = randf_range(1.3, 1.4)
		velocity.y = jump_velocity
		jump_sfx.play()
		can_double_jump = false


func handle_animations():
	if !can_change_animations:
		play_animation_based_on_state()
		return
	
	flip_character()
	
	if is_on_floor():
		if velocity.x == 0:
			current_animation_state = AnimationStates.Idle
		elif velocity.x != 0:
			current_animation_state = AnimationStates.Running
	elif current_animation_state != AnimationStates.Attack2:
		if velocity.y >= 0:
			current_animation_state = AnimationStates.Descending
		else:
			current_animation_state = AnimationStates.Ascending
	
	play_animation_based_on_state()


func play_animation_based_on_state():
	match current_animation_state:
		AnimationStates.Running:
			animated_sprite.play("running")
		AnimationStates.Ascending:
			animated_sprite.play("jumping")
		AnimationStates.Descending:
			animated_sprite.play("falling")
		AnimationStates.Upgrading:
			animated_sprite.play("upgrade")
		AnimationStates.Attack1:
			animated_sprite.play("Attack_1")
		AnimationStates.Attack2:
			animated_sprite.play("Attack_2")
		_:
			animated_sprite.play("idle") 


func upgrade_sword():
	can_move = false
	can_dash = false
	is_dashing = false
	can_change_animations = false
	current_animation_state = AnimationStates.Upgrading
	print("upgrading")
	upgrade_sfx.play()


func flip_character():
	if facing_right:
		$Flippables.scale.x = 1
	else:
		$Flippables.scale.x = -1


func start_dashing():
	# pre dash
	#can_move = false
	dash_sfx.play()
	invulnerable = true
	
	set_collision_mask_value(3, false)
	handle_dash_cooldown()
	await get_tree().create_timer(pre_dash_duration).timeout
	
	# dash
	Engine.physics_ticks_per_second = 200
	is_dashing = true
	await get_tree().create_timer(dash_duration).timeout
	
	# post dash
	Engine.physics_ticks_per_second = 60
	invulnerable = false
	set_collision_mask_value(3, true)
	is_dashing = false


func start_attack_1():
	can_move = false
	can_change_animations = false
	current_animation_state = AnimationStates.Attack1
	create_scene_at_pos(ATTACK_1, Vector2(position.x, position.y - 33))
	attack_1_collision.disabled = false


func start_attack_2():
	can_attack = false
	can_move = false
	second_attack_buffered = false
	attack_2_collision.disabled = false
	current_animation_state = AnimationStates.Attack2
	create_scene_at_pos(ATTACK_2, Vector2(position.x, position.y - 33))


func handle_dash_cooldown():
	can_dash = false
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true


func buffer_dash(buffer_length: float):
	if !Input.is_action_just_pressed("Dash"):
		return
	dash_buffered = true
	await get_tree().create_timer(buffer_length).timeout
	dash_buffered = false


func dash(delta: float):
	var dash_speed = 1 if facing_right else -1
	dash_speed *= dash_velocity * 200 * delta
	velocity = Vector2(dash_speed, 0)


func grace_period():
	invulnerable = true
	for i in 3:
		animated_sprite.visible = true
		await get_tree().create_timer(0.2).timeout
		animated_sprite.visible = false
		await get_tree().create_timer(0.2).timeout
	animated_sprite.visible = true
	invulnerable = false


func take_knockback(knockback_direction: Vector2, knockback_strength: float):
	velocity = Vector2.ZERO
	super(knockback_direction, knockback_strength)
	is_dashing = false


func take_damage(damage_taken: int, knockback_direction: Vector2, knockback_strength: float):
	if invulnerable:
		return
	hp -= damage_taken
	healthbar.health -= damage_taken
	
	grace_period()
	take_knockback(knockback_direction, knockback_strength)
	damage_taken_sfx.play()


func die():	
	can_move = false
	Engine.time_scale = 0.3
	await get_tree().create_timer(0.5).timeout
	Engine.time_scale = 1
	
	can_move = true
	get_tree().reload_current_scene()


func _on_animated_sprite_2d_animation_finished():
	if current_animation_state == AnimationStates.Upgrading:
		current_animation_state = AnimationStates.Idle
		GameManager.upgraded = true
		can_move = true
		can_dash = true
		can_attack = true
		can_change_animations = true
	
	elif current_animation_state == AnimationStates.Attack1:
		attack_1_collision.disabled = true
		
		if second_attack_buffered:
			start_attack_2()
		
		else:
			current_animation_state = AnimationStates.Idle
			can_move = true
			can_attack = true
			can_change_animations = true
	
	elif current_animation_state == AnimationStates.Attack2:
		current_animation_state = AnimationStates.Idle
		attack_2_collision.disabled = true
		can_move = true
		if is_on_floor():
			can_attack = true
		can_change_animations = true


func _on_attack_1_area_body_entered(body):
	create_scene_at_pos(HIT_PARTICLES, Vector2(body.position.x, body.position.y -15))
	damage_dealt_sfx.pitch_scale = randf_range(0.8, 1.2)
	damage_dealt_sfx.play()
	if body.is_in_group("Enemy"):
		body.take_damage(attack_1_damage, position - body.position, attack_1_knockback)


func _on_attack_2_area_body_entered(body):
	create_scene_at_pos(HIT_PARTICLES, Vector2(body.position.x, body.position.y -15))
	damage_dealt_sfx.pitch_scale = randf_range(0.8, 1.2)
	damage_dealt_sfx.play()
	if body.is_in_group("Enemy"):
		body.take_damage(attack_2_damage, position - body.position, attack_2_knockback)


func create_scene_at_pos(scene: PackedScene, position: Vector2):
	var sc = scene.instantiate()
	get_parent().add_child(sc)
	sc.global_position = position
	if !facing_right:
		sc.scale.x = -1
