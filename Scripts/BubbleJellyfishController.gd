extends CharacterBody2D

@export var animated_sprite: AnimatedSprite2D
@export var player: CharacterBody2D
@export var max_x_offset: float = 300.0
@export var min_x_offset: float = -300.0

# Movement constants
const WALK_SPEED = 200.0

# Timer for jumping
var jump_timer: float = 0.0
const JUMP_INTERVAL: float = 0.5

# Timer for attacking
var is_dead: bool = false # Prevent multiple death triggers

# Control flag
var is_active: bool = true
var walk_direction: float = 1.0

# Add a signal for when the jellyfish dies
signal died

# Preload scenes
var thunder_scene = preload("res://Scenes/thunder.tscn")
var hit_effect_scene = preload("res://Scenes/hit_effect.tscn")

var hp: float = 50.0
var initial_x_position: float = 0.0

@onready var wall_checker: RayCast2D = $WallChecker
@onready var floor_checker: RayCast2D = $FloorChecker

func _ready() -> void:
	initial_x_position = global_position.x

	# Find the player if not assigned
	if player == null:
		player = get_tree().get_first_node_in_group("Player")


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

	# --- Wandering Logic ---
	if is_on_floor():
		velocity.x = walk_direction * WALK_SPEED

	# Flip sprite based on movement direction
	animated_sprite.flip_h = walk_direction < 0
	var is_out_of_bounds = (global_position.x >= initial_x_position + max_x_offset and walk_direction > 0) or \
						(global_position.x <= initial_x_position + min_x_offset and walk_direction < 0)

	if is_on_floor() and (wall_checker.is_colliding() or is_out_of_bounds):
		walk_direction *= -1.0
		wall_checker.target_position.x *= -1

	# Play walk animation
	if animated_sprite and animated_sprite.animation != "attack":
		animated_sprite.play("walk")

	move_and_slide()

func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		animated_sprite.play("walk")

func stop_all_behaviors() -> void:
	is_active = false
	velocity.x = 0

func take_damage(_amount: float) -> void:
	if is_dead: return # Don't take damage if already dead

	# TODO: add VFX

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
