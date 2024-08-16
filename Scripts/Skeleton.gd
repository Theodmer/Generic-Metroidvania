extends LivingBeing


@export var animation_tree : AnimationTree
@export var close_range: float
@export var mid_range: float
@export var chase_range: float
@export var stop_chasing_range_buffer : float = 100
@export var stab_damage: int = 30
@export var whoosh_damage: int = 40
@export var sprite: Sprite2D
@export var speed : float = 150.0
@export var chasing := false


@onready var state : AnimationNodeStateMachinePlayback
@onready var flip_timer = $"Flip Timer"
@onready var attack_timer = $"Attack Timer"
@onready var animation_player = $AnimationPlayer
@onready var health_bar = $"Health Bar"


var player: CharacterBody2D
var distance_to_player: float
var was_facing_right := false
var facing_right := false
var can_attack := true
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready():
	state = animation_tree.get("parameters/playback")
	player = get_tree().get_first_node_in_group("Player")
	
	close_range = $"Flipabbles/Close Range/CollisionShape2D".shape.radius
	mid_range = $"Flipabbles/Medium Range/CollisionShape2D".shape.radius
	chase_range = $"Flipabbles/Long Range/CollisionShape2D".shape.radius
	
	# set health bar stuff
	health_bar.max_value = max_hp
	health_bar.init_health(max_hp)



func _physics_process(delta):
	apply_gravity(delta)
	
	calculate_distance_to_player()
	decide_next_attack()
	check_if_facing_right()
	flip()
	
	decide_chasing()
	chase()


func apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta
		move_and_slide()

func decide_chasing():
	var dist = abs(distance_to_player)
	
	if dist < chase_range and dist > mid_range:
		animation_tree["parameters/conditions/is_chasing"] = true
	
	elif dist <= close_range:
		chasing = false
		animation_tree["parameters/conditions/is_chasing"] = false
	
	elif dist > chase_range + stop_chasing_range_buffer:
		chasing = false
		animation_tree["parameters/conditions/is_chasing"] = false
		state.travel("Idle")


func chase():
	if chasing:
		velocity.x = speed if distance_to_player < 0 else -speed
		move_and_slide()
	


func calculate_distance_to_player():
	distance_to_player = position.x - player.position.x


func check_if_facing_right():
	was_facing_right = facing_right
	
	if distance_to_player > 0:
		facing_right = false
	else:
		facing_right = true


func flip():
	if was_facing_right == facing_right or !flip_timer.is_stopped():
		return
	
	if facing_right:
		flip_timer.start()
		await flip_timer.timeout
		$Flipabbles.scale.x = -1
		$CollisionShape2D.position.x = -abs($CollisionShape2D.position.x)
	else:
		flip_timer.start()
		await flip_timer.timeout
		$Flipabbles.scale.x = 1


func decide_next_attack():
	if abs(distance_to_player) < close_range and can_attack:
		can_attack = false
		attack_timer.start()
		state.travel("Whoosh Attack")
	elif abs(distance_to_player) < mid_range and can_attack:
		can_attack = false
		attack_timer.start()
		state.travel("Stab Attack")


func take_damage(damage_taken: int, knockback_direction: Vector2, knockback_strength: float):
	hp -= damage_taken
	health_bar.health -= damage_taken
	be_red_for_seconds(0.2)
	state.travel("Damaged")


func _on_attack_timer_timeout():
	can_attack = true


func _on_attack_area_body_entered(body):
	if !body.is_in_group("Player"):
		return
	var damage_to_give = stab_damage if animation_player.current_animation == "Stab Attack" else whoosh_damage
	body.take_damage(damage_to_give, body.position - position, 3)


func be_red_for_seconds(duration: float):
	sprite.modulate = Color.RED
	await get_tree().create_timer(duration).timeout
	sprite.modulate = Color.WHITE
	

func die():
	print("skeleton died!")
	$CollisionShape2D.disabled = true
	set_physics_process(false)
	animation_tree["parameters/conditions/is_dead"] = true
