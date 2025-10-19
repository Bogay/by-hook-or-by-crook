extends Area2D

@export var speed: float = 600.0
@export var damage: float = 50.0
@export var lifetime: float = 5.0

var direction: Vector2 = Vector2.RIGHT
var damaged_bodies: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
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
	# Don't hit the player who threw it
	if body.is_in_group("Player"):
		return

	# Deal damage if the target has take_damage method
	if body.has_method("take_damage") and not damaged_bodies.has(body):
		body.take_damage(damage)
		damaged_bodies.append(body)

	# Destroy the spear on impact
	queue_free()
