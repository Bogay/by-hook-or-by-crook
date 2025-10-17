extends CharacterBody2D

@export var animated_sprite: AnimatedSprite2D
@export var player: CharacterBody2D

# Movement constants
const DETECTION_DISTANCE = 3.0 * 64.0  # 3 units in pixels (assuming 64 pixels per unit)
const WALK_SPEED = 100.0
const JUMP_FORCE = -400.0

# Timer for jumping
var jump_timer: float = 0.0
const JUMP_INTERVAL: float = 2.0

func _ready() -> void:
	# Find the player if not assigned
	if player == null:
		player = get_node("/root/BasicScene/Player")

	jump_timer = JUMP_INTERVAL

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Update jump timer
	jump_timer -= delta
	if jump_timer <= 0 and is_on_floor():
		_jump()
		jump_timer = JUMP_INTERVAL

	# Check distance to player
	if player != null:
		var distance = global_position.distance_to(player.global_position)

		# Walk away from player if distance is less than 3 units
		if distance < DETECTION_DISTANCE:
			# Calculate direction away from player (reversed)
			var direction = sign(global_position.x - player.global_position.x)
			if direction == 0:
				direction = 1  # Default to right if positions are exactly the same

			velocity.x = direction * WALK_SPEED

			# Flip sprite based on movement direction
			if animated_sprite:
				animated_sprite.flip_h = direction < 0
		else:
			velocity.x = 0
	else:
		velocity.x = 0

	move_and_slide()

func _jump() -> void:
	velocity.y = JUMP_FORCE
