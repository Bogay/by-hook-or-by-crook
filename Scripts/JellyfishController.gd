extends CharacterBody2D

@export var animated_sprite: AnimatedSprite2D
@export var player: CharacterBody2D

# Movement constants
const DETECTION_DISTANCE = 3.0 * 64.0  # 3 units in pixels (assuming 64 pixels per unit)
const WALK_SPEED = 100.0
const JUMP_FORCE = -600.0

# Timer for jumping
var jump_timer: float = 0.0
const JUMP_INTERVAL: float = 0.5

# Timer for attacking
var attack_timer: float = 0.0
const ATTACK_INTERVAL: float = 4.0
var is_attacking: bool = false

# Control flag
var is_active: bool = true

# Preload thunder scene
var thunder_scene = preload("res://Scenes/thunder.tscn")

func _ready() -> void:
	# Find the player if not assigned
	if player == null:
		player = get_tree().get_first_node_in_group("Player")

	jump_timer = JUMP_INTERVAL
	attack_timer = ATTACK_INTERVAL

	# Connect animation finished signal
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Skip all behaviors if not active
	if not is_active:
		velocity.x = 0
		move_and_slide()
		return

	# Update jump timer
	jump_timer -= delta
	if jump_timer <= 0 and is_on_floor() and not is_attacking:
		_jump()
		jump_timer = JUMP_INTERVAL

	# Update attack timer
	attack_timer -= delta
	if attack_timer <= 0 and not is_attacking:
		_attack()
		attack_timer = ATTACK_INTERVAL

	# Movement and animation (only if not attacking)
	if not is_attacking:
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

		# Play walk animation
		if animated_sprite and animated_sprite.animation != "attack":
			animated_sprite.play("walk")
	else:
		# Stop moving during attack
		velocity.x = 0

	move_and_slide()

func _jump() -> void:
	velocity.y = JUMP_FORCE

func _attack() -> void:
	if player == null:
		return

	is_attacking = true

	# Determine if player is on the left
	var player_on_left = player.global_position.x < global_position.x

	# Flip sprite to face the player
	if animated_sprite:
		animated_sprite.flip_h = player_on_left
		animated_sprite.play("attack")

	# Spawn thunder after a short delay
	await get_tree().create_timer(0.2).timeout

	if player != null:
		_spawn_thunder()

func _spawn_thunder() -> void:
	var thunder = thunder_scene.instantiate()
	get_parent().add_child(thunder)

	# Calculate hand position (offset from jellyfish center)
	var hand_offset = Vector2(16, 0)  # Adjust this based on your sprite
	if animated_sprite and animated_sprite.flip_h:
		hand_offset.x = -16

	var from_pos = global_position + hand_offset
	var to_pos = player.global_position

	thunder.setup(from_pos, to_pos, player)

func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false
		animated_sprite.play("walk")

func stop_all_behaviors() -> void:
	is_active = false
	is_attacking = false
	velocity.x = 0
