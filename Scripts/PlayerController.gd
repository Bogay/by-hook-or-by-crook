extends CharacterBody2D

@export_category("Necesary Child Nodes")
@export var animated_sprite: AnimatedSprite2D
@export var collider: CollisionShape2D
@export var attack_area: Area2D
@export var data: Resource

# Spear throwing
const SPEAR_SCENE = preload("res://Scenes/spear.tscn")
var can_throw_spear: bool = true
var spear_throw_cooldown: float = 2.0
var throw_target_position: Vector2 = Vector2.ZERO

# HP System
var max_hp: float = 100.0
var current_hp: float = 100.0

signal hp_changed(new_hp: float)

enum State {
	IDLE,
	RUN,
	JUMP,
	ATTACK,
	THROW,
	DEAD
}

#Movement variables
var move_direction: Vector2 = Vector2.ZERO
var facing_right: bool = true
var external_velocity: Vector2 = Vector2.ZERO
var coyoteActive = false
var jumpWasPressed = false

var can_attack: bool = true

#State
var current_state = State.IDLE

func _ready() -> void:
	data._init_data()
	animated_sprite.animation_finished.connect(self._on_animation_finished)
	attack_area.body_entered.connect(_on_attack_area_body_entered)

func _on_attack_area_body_entered(body):
	if body.has_method("take_damage") == false:
		return
	body.take_damage(data.attack_damage)

func _on_animation_finished():
	if animated_sprite.animation == "attack2":
		attack_area.get_node("CollisionShape2D").disabled = true
		if is_on_floor():
			current_state = State.IDLE
	elif animated_sprite.animation == "throw":
		# Spawn the spear after throw animation completes
		_spawn_spear()
		if is_on_floor():
			current_state = State.IDLE

func _process(_delta):
	_input_handler()

func _physics_process(delta: float) -> void:
	#Move Input
	move_direction = Input.get_vector("left", "right", "down", "up")
	if move_direction != Vector2.ZERO:
		move_direction = move_direction.normalized()
		if current_state != State.ATTACK:
			facing_right = move_direction.x > 0
	else:
		move_direction = Vector2.ZERO

	_ground_check()
	_move(delta)
	_state_machine()
	_animate()

func _input_handler():
	if current_state == State.ATTACK or current_state == State.THROW:
		return

	if Input.is_action_just_pressed("jump"):
		jumpWasPressed = true
		_bufferJump()

	if Input.is_action_just_pressed("main_attack") and can_attack:
		var mouse_pos = get_global_mouse_position()
		facing_right = mouse_pos.x > global_position.x
		current_state = State.ATTACK

	if Input.is_action_just_pressed("secondary_attack") and can_throw_spear:
		var mouse_pos = get_global_mouse_position()
		throw_target_position = mouse_pos
		facing_right = mouse_pos.x > global_position.x
		current_state = State.THROW

func _ground_check():
	if is_on_floor():
		coyoteActive = true
		if jumpWasPressed:
			_jump()
	elif coyoteActive:
		_coyoteTime()

func _move(delta: float) -> void:
	velocity = _calculate_velocity(velocity, delta)
	move_and_slide()


func _calculate_velocity(vel: Vector2, delta: float) -> Vector2:
	vel.x = _calculate_horizontal_velocity(vel.x, delta)
	vel.y = _calculate_vertical_velocity(vel.y, delta)
	return vel

func _calculate_horizontal_velocity(velX: float, delta: float) -> float:
	if current_state == State.ATTACK or current_state == State.THROW:
		return 0.0

	velX = lerp(velX, move_direction.x * data.maxSpeed, data.acceleration * delta)

	if (external_velocity.x != 0):
		velX = external_velocity.x
		external_velocity.x = 0

	return velX

func _calculate_vertical_velocity(velY: float, delta: float) -> float:
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * data.gravityScale
	if not is_on_floor():
		gravity *= data.descendingGravityFactor if velY > 0 else 1
		velY += gravity * delta
		velY = min(velY, data.terminalVelocity)
	else:
		velY = 0

	if (external_velocity.y != 0):
		velY = external_velocity.y
		external_velocity.y = 0

	return velY

func _state_machine():
	match current_state:
		State.IDLE:
			if move_direction.x != 0:
				current_state = State.RUN
		State.RUN:
			if move_direction.x == 0:
				current_state = State.IDLE
		State.JUMP:
			if is_on_floor() and velocity.y == 0:
				current_state = State.IDLE
		State.ATTACK:
			_start_attack()
		State.THROW:
			_start_throw()
		State.DEAD:
			pass

func _animate():
	match current_state:
		State.IDLE:
			animated_sprite.animation = "idle2"
		State.RUN:
			animated_sprite.animation = "walk2"
		State.JUMP:
			animated_sprite.animation = "jump2"
		State.ATTACK:
			animated_sprite.animation = "attack2"
		State.THROW:
			animated_sprite.animation = "throw"
		State.DEAD:
			animated_sprite.animation = "dead"

	animated_sprite.flip_h = not facing_right
	animated_sprite.play()

func _start_attack():
	can_attack = false
	attack_area.get_node("CollisionShape2D").disabled = false
	await get_tree().create_timer(data.attack_cooldown).timeout
	can_attack = true

func _jump():
	if (is_on_floor() or coyoteActive) and current_state != State.ATTACK:
		external_velocity.y = - data.jumpMagnitude
		coyoteActive = false
		jumpWasPressed = false
		current_state = State.JUMP


func _coyoteTime():
	await get_tree().create_timer(data.coyoteTime).timeout
	coyoteActive = false

func _bufferJump():
	await get_tree().create_timer(data.jumpBuffering).timeout
	jumpWasPressed = false

func take_damage(amount: float) -> void:
	current_hp = max(0.0, current_hp - amount)
	hp_changed.emit(current_hp)
	if current_hp <= 0:
		current_state = State.DEAD
		_handle_death()

func _handle_death() -> void:
	# Wait for death animation to play
	await get_tree().create_timer(1.0).timeout
	# Switch to game over screen
	get_tree().change_scene_to_file("res://Scenes/game_over.tscn")

func _start_throw():
	can_throw_spear = false
	# Start cooldown
	await get_tree().create_timer(spear_throw_cooldown).timeout
	can_throw_spear = true

func _spawn_spear():
	var spear = SPEAR_SCENE.instantiate()
	# Get the root scene to add the spear to
	get_tree().root.add_child(spear)

	# Position spear at player position (slightly offset toward throw direction)
	var offset = Vector2(30, -20) if facing_right else Vector2(-30, -20)
	spear.global_position = global_position + offset

	# Calculate direction from player to target
	var direction = (throw_target_position - global_position).normalized()
	spear.set_direction(direction)
