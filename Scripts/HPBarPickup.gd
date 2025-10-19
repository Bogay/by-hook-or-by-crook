extends Area2D

@export var hp_border: TextureRect
@export var hp_fill: TextureRect

var current_hp: float = 100.0
var max_hp: float = 100.0
var base_scale: Vector2

var is_flying_to_player: bool = false
var target_player: Node = null
const FLY_SPEED: float = 800.0

var physics_body: RigidBody2D = null
var is_placed_on_ground: bool = false
var has_landed: bool = false

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

func _physics_process(delta: float) -> void:
	# Don't move if placed on ground
	if is_placed_on_ground:
		return

	if is_flying_to_player and target_player and is_instance_valid(target_player):
		# Fly towards player
		var direction = (target_player.global_position - global_position).normalized()
		global_position += direction * FLY_SPEED * delta

		# Check if reached player
		if global_position.distance_to(target_player.global_position) < 50:
			_pickup_by_player()

func _on_player_hp_changed(new_hp: float) -> void:
	current_hp = new_hp
	update_hp_bar()

func update_hp_bar() -> void:
	if hp_fill and hp_border:
		var hp_ratio = current_hp / max_hp if max_hp > 0 else 0.0
		hp_fill.scale.x = base_scale.x * hp_ratio

func hit_by_spear_pickup(player: Node) -> void:
	print("HPBar hit by spear! Flying to player...")
	is_flying_to_player = true
	target_player = player

func _pickup_by_player() -> void:
	if target_player and target_player.has_method("pickup_item"):
		target_player.pickup_item(self, "HPBar")
		# Don't hide - will be positioned on player's head
		is_flying_to_player = false
		print("HPBar picked up!")

func place_on_ground() -> void:
	# Called when player uses the HPBar
	show()
	is_placed_on_ground = true

	# Rotate to vertical (90 degrees)
	rotation = PI / 2.0
	print("HPBar placed vertically at: ", global_position)

	# Scale down the visual elements to make it shorter
	if hp_border:
		#hp_border.scale = Vector2(0.4, 0.3)  # Make it thin and short
		print("HPBorder scaled to: ", hp_border.scale)

	if hp_fill:
		#hp_fill.scale = Vector2(0.4, 0.3)  # Match border scale
		print("HPFill scaled to: ", hp_fill.scale)

	# Create RigidBody2D for physics and gravity
	if physics_body == null:
		physics_body = RigidBody2D.new()
		# Add to level root (not UIRoot) so it can fall independently
		# Find the actual level node (usually named Level01, Level02, etc.)
		var current = get_parent()
		while current != null and current.get_parent() != null:
			var parent_name = current.name
			if parent_name.begins_with("Level") or current.get_parent().name == "root":
				break
			current = current.get_parent()

		if current:
			current.add_child(physics_body)
		else:
			# Fallback: add to root
			get_tree().root.add_child(physics_body)

		physics_body.global_position = global_position
		physics_body.rotation = rotation

		# Move visual elements to RigidBody2D
		if hp_border:
			remove_child(hp_border)
			physics_body.add_child(hp_border)
		if hp_fill:
			remove_child(hp_fill)
			physics_body.add_child(hp_fill)

		# Create collision shape matching the scaled HPBar size
		var collision_shape = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()

		# Smaller collision for the scaled bar
		rect_shape.size = Vector2(170, 30)
		collision_shape.shape = rect_shape

		physics_body.add_child(collision_shape)

		# Enable gravity and set mass
		physics_body.gravity_scale = 1.0
		physics_body.mass = 5.0
		physics_body.lock_rotation = true  # Keep vertical orientation

		# Connect to detect landing
		physics_body.body_entered.connect(_on_physics_body_landed)

		print("Added RigidBody2D with gravity for platform collision (30x10)")

		# Hide/disable the original Area2D
		hide()

	# Disable Area2D collision (no longer pickupable)
	var area_collision = get_node_or_null("CollisionShape2D")
	if area_collision:
		area_collision.disabled = true

func _on_physics_body_landed(body: Node) -> void:
	if not has_landed and physics_body:
		has_landed = true
		# Freeze the body when it lands
		physics_body.freeze = true
		print("HPBar landed and froze at: ", physics_body.global_position)
