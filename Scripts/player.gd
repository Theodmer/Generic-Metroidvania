extends LivingBeing

@export_group("Movement")
@export var run_speed: float = 350.0
@export var jump_velocity: float = -500.0
@export var coyote_time_duration: float = 0.15
@export var dash_velocity: float = 900.0
@export var dash_duration: float = 0.15
@export var pre_dash_duration: float = 0.1
@export var dash_cooldown: float = 0.8



@export_group("SFX")
@export var footstep_delay: float = 0.1
@export var dash_sfx: AudioStreamPlayer2D
@export var jump_sfx: AudioStreamPlayer2D
@export var footstep_sfx: AudioStreamPlayer2D
@export var footstep_timer: Timer

var direction: int = 0
var facing_right := true
var can_move := true
var is_dashing := false
var can_dash := true
var can_double_jump := true
var coyote_time := false
var playing_footstep_sfx := false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite = $AnimatedSprite2D


func _physics_process(delta):
	handle_grounded()
	apply_gravity(delta)
	
	handle_animations()
	play_footstep_sfx()
	
	calculate_direction()
	handle_movement(delta)


func apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta


func give_velocity():
	if direction and can_move:
		velocity.x = direction * run_speed
	else:
		velocity.x = move_toward(velocity.x, 0, run_speed)
	
	if being_knocked_back:
		velocity = Vector2(knockback.x, knockback.y / 2.0)


func play_footstep_sfx():
	if !direction or !is_on_floor():
		return
	if footstep_timer.time_left > 0:
		return
	footstep_sfx.pitch_scale = randf_range(0.8, 1.2)
	footstep_sfx.play()
	footstep_timer.start()


func handle_grounded():
	if is_on_floor():
		can_double_jump = true


func handle_movement(delta: float):
	handle_movement_input()
	if is_dashing:
		dash(delta)
	elif !is_dashing:
		give_velocity()
	elif !can_move:
		velocity = Vector2(0,0)
	
	var was_on_floor = is_on_floor()
	move_and_slide()
	if was_on_floor and !is_on_floor():
		start_coyote_timer()


func start_coyote_timer():
	coyote_time = true
	await get_tree().create_timer(coyote_time_duration).timeout
	coyote_time = false


func handle_movement_input():
	if Input.is_action_just_pressed("Jump"):
		if is_on_floor() or coyote_time:
			jump_sfx.pitch_scale = randf_range(0.9, 1.1)
			jump()
			coyote_time = false
		elif can_double_jump:
			jump_sfx.pitch_scale = randf_range(1.3, 1.4)
			jump()
			can_double_jump = false

	if Input.is_action_just_pressed("Dash") and can_dash and !is_dashing:
		start_dashing()


func calculate_direction():
	if !can_move:
		return
	
	direction = Input.get_axis("Left", "Right")
	if direction > 0:
		facing_right = true
	elif direction < 0:
		facing_right = false


func jump():
	velocity.y = jump_velocity
	jump_sfx.play()


func handle_animations():
	flip_character()
	if is_on_floor():
		if direction:
			animated_sprite.play("running")
		else:
			animated_sprite.play("idle")
	else:
		if velocity.y > 0:
			animated_sprite.play("falling")
		else:
			animated_sprite.play("jumping")


func flip_character():
	if facing_right:
		animated_sprite.flip_h = false
	else:
		animated_sprite.flip_h = true


func start_dashing():
	# pre dash
	can_move = false
	dash_sfx.play()
	handle_dash_cooldown()
	await get_tree().create_timer(pre_dash_duration).timeout
	
	# dash
	Engine.physics_ticks_per_second = 200
	is_dashing = true
	await get_tree().create_timer(dash_duration).timeout
	
	# post dash
	Engine.physics_ticks_per_second = 60
	is_dashing = false
	can_move = true


func handle_dash_cooldown():
	can_dash = false
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true


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
	grace_period()
	super(damage_taken, knockback_direction, knockback_strength)


func die():
	super()	
	
	can_move = false
	Engine.time_scale = 0.3
	await get_tree().create_timer(0.3).timeout
	Engine.time_scale = 1
	
	can_move = true
	get_tree().reload_current_scene()
