extends Node2D

@export var speed: float = 250.0
@export var damage: float = 15.0

var player
var velocity: Vector2 = Vector2.ZERO

func add_velocity(additional_velocity: Vector2) -> void:
	velocity += additional_velocity

func _ready() -> void:
	# Find the player
	player = get_tree().get_first_node_in_group("Player")
	
	# Connect the body_entered signal to a function
	$Area2D.body_entered.connect(_on_body_entered)

	# The projectile will destroy itself after 10 seconds
	await get_tree().create_timer(10.0).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta: float) -> void:
	if is_instance_valid(player):
		# Homing behavior: constantly update direction towards the player
		var direction = (player.global_position - global_position).normalized()
		velocity += direction * 2 * speed * delta
		
		# Make the attack point towards the player
		rotation = velocity.angle()

	# Move the attack
	var _velocity = velocity.normalized() * speed
	global_position += _velocity * delta

func _on_body_entered(body: Node2D) -> void:
	# Check if the body that entered is the player
	if body == player:
		# Check if the player has a take_damage function
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		# Destroy the magic attack on impact
		queue_free()
