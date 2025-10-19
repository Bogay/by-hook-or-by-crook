extends CharacterBody2D

@export var animated_sprite: AnimatedSprite2D
@export var player: CharacterBody2D

# Behavior toggles
@export var enable_walking: bool = true
@export var enable_jumping: bool = true
@export var track_player_for_attack: bool = true
@export var thunder_damage: float = 40.0

# Movement constants
const DETECTION_DISTANCE = 20.0 * 64.0 # 3 units in pixels (assuming 64 pixels per unit)
const MIN_DISTANCE = 5 * 64.0 # Minimum distance to maintain from player
const WALK_SPEED = 200.0
const JUMP_FORCE = -600.0

# Timer for jumping
var jump_timer: float = 0.0
const JUMP_INTERVAL: float = 0.5

# Timer for attacking
var attack_timer: float = 0.0
const ATTACK_INTERVAL: float = 5.0
var is_attacking: bool = false
var is_dead: bool = false # Prevent multiple death triggers

# Control flag
var is_active: bool = true

# Add a signal for when the jellyfish dies
signal died

# Preload scenes
var thunder_scene = preload("res://Scenes/thunder.tscn")
var hit_effect_scene = preload("res://Scenes/hit_effect.tscn")

var hp: float = 50.0

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

	# Skip all behaviors if not active or dead
	if not is_active or is_dead:
		velocity.x = 0
		move_and_slide()
		return

	# Update jump timer (only if jumping is enabled)
	if enable_jumping:
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
		# Check distance to player (only if walking is enabled)
		if enable_walking and player != null:
			var distance = global_position.distance_to(player.global_position)

			# Move based on distance from player
			if distance < DETECTION_DISTANCE:
				var direction: float

				if distance < MIN_DISTANCE:
					# Too close - move away from player
					direction = sign(global_position.x - player.global_position.x)
				else:
					# Within range but not too close - move toward player
					direction = sign(player.global_position.x - global_position.x)

				if direction == 0:
					direction = 1 # Default to right if positions are exactly the same

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
	is_attacking = true

	# Determine attack direction
	var attack_to_left = false
	if track_player_for_attack and player != null:
		# Track player position
		attack_to_left = player.global_position.x < global_position.x
	else:
		# Fixed direction - always attack to the left
		attack_to_left = true

	# Flip sprite based on attack direction
	if animated_sprite:
		animated_sprite.flip_h = attack_to_left
		animated_sprite.play("attack")

	# Spawn thunder after a short delay
	await get_tree().create_timer(0.2).timeout

	# Check if still active after the delay
	if not is_active or is_dead:
		return

	_spawn_thunder(attack_to_left)

func _spawn_thunder(attack_to_left: bool) -> void:
	var thunder = thunder_scene.instantiate()
	get_parent().add_child(thunder)

	# Calculate hand position (offset from jellyfish center)
	var hand_offset = Vector2(16, 0) # Adjust this based on your sprite
	if attack_to_left:
		hand_offset.x = -16

	var from_pos = global_position + hand_offset
	var to_pos: Vector2

	# Determine target position
	if player != null:
		# Set damage before setup
		thunder.damage = thunder_damage

		if track_player_for_attack:
			# Track player's full position (X and Y)
			to_pos = player.global_position
		else:
			# Horizontal shot only - use player's X but jellyfish's Y
			to_pos = Vector2(player.global_position.x, from_pos.y)

		thunder.setup(from_pos, to_pos, player)
	else:
		# Fallback if no player found
		to_pos = from_pos + Vector2(-500, 0)
		thunder.damage = thunder_damage
		thunder.setup(from_pos, to_pos, null)

func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false
		animated_sprite.play("walk")

func stop_all_behaviors() -> void:
	is_active = false
	is_attacking = false
	velocity.x = 0

func take_damage(amount: float) -> void:
	if is_dead: return # Don't take damage if already dead

	hp -= amount
	print("Jellyfish took ", amount, " damage. Current HP: ", hp)

	# Spawn hit particle effect
	var hit_effect = hit_effect_scene.instantiate()
	get_parent().add_child(hit_effect)
	hit_effect.global_position = global_position

	# Add Hit Flash Effect
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
	# Use self_modulate to avoid interfering with modulate from other sources
	animated_sprite.self_modulate = Color.WHITE
	tween.tween_property(animated_sprite, "self_modulate", Color(1, 1, 1, 1), 0.1)

	if hp <= 0:
		_die()

func _die() -> void:
	if is_dead: return
	is_dead = true
	
	# Stop all movement and logic
	stop_all_behaviors()
	
	# Disable collision so the player can pass through
	get_node("CollisionShape2D").set_deferred("disabled", true)
	
	# Emit signal for screen shake
	died.emit()
	
	print("Jellyfish defeated!")
	
	# Play death animation and fade out
	animated_sprite.play("walk") # Or a dedicated "death" animation if you have one
	
	var tween = create_tween()
	tween.set_parallel(true)
	# Fade out the sprite
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.5).set_delay(0.2)
	# Make it "fall" through the floor
	tween.tween_property(self, "position:y", position.y + 30, 0.7).set_ease(Tween.EASE_IN)
	
	# Wait for the tween to finish, then remove the node
	await tween.finished
	queue_free()
