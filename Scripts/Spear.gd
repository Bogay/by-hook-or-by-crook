extends Area2D

@export var speed: float = 600.0
@export var damage: float = 10.0
@export var lifetime: float = 5.0

const MAX_PARENT_DEPTH: int = 5  # How many parent levels to check for methods

var direction: Vector2 = Vector2.RIGHT
var damaged_bodies: Array = []
var player: Node = null  # Reference to player for pickup

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)  # Detect Area2D nodes like GameButton/HPBar
	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	# Rotate the spear to face the direction
	# The sprite is already rotated 90 degrees, so we just apply the direction angle directly
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	print("Spear hit: ", body.name, " (type: ", body.get_class(), ")")

	# Don't hit the player who threw it
	if body.is_in_group("Player"):
		return

	# Check for pickupable items by traversing parent tree
	var current_node = body
	for i in range(MAX_PARENT_DEPTH):
		print("  Checking node: ", current_node.name, " for hit_by_spear_pickup method")
		if current_node.has_method("hit_by_spear_pickup"):
			print("  Found hit_by_spear_pickup on: ", current_node.name)
			if player:
				current_node.hit_by_spear_pickup(player)
			else:
				print("  ERROR: No player reference!")
			queue_free()
			return
		if current_node.get_parent():
			current_node = current_node.get_parent()
		else:
			break

	# Deal damage if the target has take_damage method
	if body.has_method("take_damage") and not damaged_bodies.has(body):
		body.take_damage(damage)
		damaged_bodies.append(body)

	# Destroy the spear on impact
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	print("Spear hit Area2D: ", area.name, " (type: ", area.get_class(), ")")

	# Check if this area belongs to the player - if so, ignore it
	var current_check = area
	for i in range(MAX_PARENT_DEPTH):
		if current_check.is_in_group("Player"):
			print("  Ignoring area - belongs to player")
			return
		if current_check.get_parent():
			current_check = current_check.get_parent()
		else:
			break

	# Check for pickupable items by traversing parent tree
	var current_node = area
	for i in range(MAX_PARENT_DEPTH):
		print("  Checking node: ", current_node.name, " for hit_by_spear_pickup method")
		if current_node.has_method("hit_by_spear_pickup"):
			print("  Found hit_by_spear_pickup on: ", current_node.name)
			if player:
				current_node.hit_by_spear_pickup(player)
			else:
				print("  ERROR: No player reference!")
			queue_free()
			return
		if current_node.get_parent():
			current_node = current_node.get_parent()
		else:
			break

	print("  No hit_by_spear_pickup method found in parent tree")
	# Destroy the spear on impact
	queue_free()
