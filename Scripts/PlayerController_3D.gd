extends CharacterBody3D

@export_category("Necesary Child Nodes")
@export var animated_sprite: AnimatedSprite3D
@export var collider: CollisionShape3D
@export var data: Resource

enum State {
	IDLE,
	RUN,
	JUMP,
	ATTACK,
	DEAD
}

#Movement variables
var move_direction: Vector2 = Vector2.ZERO
var facing_right: bool = true
var external_velocity: Vector2 = Vector2.ZERO
var coyoteActive = false
var jumpWasPressed = false

#State
var current_state = State.IDLE

func _ready() -> void:
	data._init_data()

func _process(delta):
	_input_handler()

func _physics_process(delta: float) -> void:

	#Move Input
	move_direction = Input.get_vector("left", "right", "down", "up")
	if move_direction != Vector2.ZERO:
		move_direction = move_direction.normalized()
		facing_right = move_direction.x > 0
	else:
		move_direction = Vector2.ZERO

	_ground_check()
	_move(delta)
	_state_machine()
	_animate()

	print(velocity)

func _input_handler():
	#Jump
	if Input.is_action_just_pressed("jump"):
		jumpWasPressed = true
		_bufferJump()

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


func _calculate_velocity(vel: Vector3, delta: float) -> Vector3:
	vel.x = _calculate_horizontal_velocity(vel.x, delta)
	vel.y = _calculate_vertical_velocity(vel.y, delta)
	return vel

func _calculate_horizontal_velocity(velX: float, delta: float) -> float:
	velX = lerp(velX, move_direction.x * data.maxSpeed, data.acceleration * delta)

	if(external_velocity.x != 0):
		velX = external_velocity.x
		external_velocity.x = 0

	return velX

func _calculate_vertical_velocity(velY: float, delta: float) -> float:
	var gravity = -ProjectSettings.get_setting("physics/3d/default_gravity") * data.gravityScale
	if not is_on_floor():
		gravity *= data.descendingGravityFactor if velY > 0 else 1
		velY += gravity * delta
		velY = min(velY, data.terminalVelocity)
	else:
		velY = 0

	if(external_velocity.y != 0):
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
			if is_on_floor():
				current_state = State.IDLE
		State.ATTACK:
			pass
		State.DEAD:
			pass

func _animate():
	match current_state:
		State.IDLE:
			animated_sprite.animation = "idle"
		State.RUN:
			animated_sprite.animation = "walk"
		State.JUMP:
			animated_sprite.animation = "jump"
		State.ATTACK:
			animated_sprite.animation = "attack"
		State.DEAD:
			animated_sprite.animation = "dead"

	animated_sprite.flip_h = not facing_right
	animated_sprite.play()

func _jump():
	if is_on_floor() or coyoteActive:
		external_velocity.y = data.jumpMagnitude
		coyoteActive = false
		jumpWasPressed = false
		current_state = State.JUMP


func _coyoteTime():
	await get_tree().create_timer(data.coyoteTime).timeout
	coyoteActive = false

func _bufferJump():
	await get_tree().create_timer(data.jumpBuffering).timeout
	jumpWasPressed = false