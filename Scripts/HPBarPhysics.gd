extends RigidBody2D

@export var hp_border: TextureRect
@export var hp_fill: TextureRect

var current_hp: float = 100.0
var max_hp: float = 100.0
var base_scale: Vector2

# Tilt physics
var accumulated_tilt: float = 0.0
const TILT_PER_HIT: float = 0.4  # Radians to tilt per hit
const MAX_TILT_ANGLE: float = 0.8  # Radians (~45 degrees) - drops after 2 hits
var has_dropped: bool = false
var drop_started: bool = false

func _ready() -> void:
	if hp_fill:
		base_scale = hp_fill.scale

	# Connect to player HP changes
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_signal("hp_changed"):
		player.hp_changed.connect(_on_player_hp_changed)
		current_hp = player.current_hp
		max_hp = player.max_hp
		update_hp_bar()

	# Make it not affected by gravity initially (floating platform)
	gravity_scale = 0.0

	# Set to kinematic mode initially (won't fall until tilted enough)
	freeze = true

	# Connect body entered signal for ground detection
	body_entered.connect(_on_body_entered)

func _on_player_hp_changed(new_hp: float) -> void:
	current_hp = new_hp
	update_hp_bar()

func update_hp_bar() -> void:
	if hp_fill and hp_border:
		var hp_ratio = current_hp / max_hp if max_hp > 0 else 0.0
		hp_fill.scale.x = base_scale.x * hp_ratio

func hit_by_spear(hit_position: Vector2) -> void:
	if has_dropped:
		return

	# Determine which side was hit
	var hit_from_left = hit_position.x < global_position.x
	print("HPBar hit! From left: ", hit_from_left, " at position: ", hit_position)

	# Add tilt in the direction of the hit
	var tilt_direction = 1.0 if hit_from_left else -1.0
	accumulated_tilt += tilt_direction * TILT_PER_HIT

	# Apply the tilt
	rotation = accumulated_tilt
	print("Accumulated tilt: ", accumulated_tilt, " (", rad_to_deg(accumulated_tilt), " degrees)")

	# Check if tilt exceeds threshold
	if abs(accumulated_tilt) >= MAX_TILT_ANGLE and not drop_started:
		drop_started = true
		print("MAX TILT REACHED! Starting drop...")
		_start_drop()

func _start_drop() -> void:
	print("HPBar starting to drop! Unfreezing and enabling gravity...")
	# Use call_deferred to change physics state after collision processing
	call_deferred("_apply_drop_physics")

func _apply_drop_physics() -> void:
	# Unfreeze and enable gravity (called via deferred)
	freeze = false
	gravity_scale = 1.0

	# Set rotation to vertical (pointing down)
	rotation = PI / 2.0 if accumulated_tilt > 0 else -PI / 2.0
	print("Rotation set to vertical: ", rad_to_deg(rotation), " degrees")

	# Scale down the collision shape directly
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var rect_shape = collision_shape.shape as RectangleShape2D
		# Make it thin and short (was 384x64, make it ~40x100)
		rect_shape.size = Vector2(40, 100)
		print("Collision shape resized to: ", rect_shape.size)

	# Scale the visual TextureRect nodes
	if hp_border:
		hp_border.scale = Vector2(0.1, 0.3)
		print("HPBorder scaled to: ", hp_border.scale)

	if hp_fill:
		hp_fill.scale = Vector2(0.1, 0.3)
		print("HPFill scaled to: ", hp_fill.scale)

	# Lock rotation so it falls straight down
	lock_rotation = true

func _on_body_entered(body: Node) -> void:
	# When hitting ground, stick in place
	if drop_started and not has_dropped:
		has_dropped = true
		print("HPBar hit ground! Sticking in place...")
		call_deferred("_stick_to_ground")

func _stick_to_ground() -> void:
	freeze = true
	# Make it static
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
