extends Area2D

var is_flying_to_player: bool = false
var target_player: Node = null
const FLY_SPEED: float = 800.0

func _physics_process(delta: float) -> void:
	if is_flying_to_player and target_player and is_instance_valid(target_player):
		# Fly towards player
		var direction = (target_player.global_position - global_position).normalized()
		global_position += direction * FLY_SPEED * delta

		# Check if reached player
		if global_position.distance_to(target_player.global_position) < 50:
			_pickup_by_player()

func hit_by_spear_pickup(player: Node) -> void:
	print("GameButton hit by spear! Flying to player...")
	is_flying_to_player = true
	target_player = player

func _pickup_by_player() -> void:
	if target_player and target_player.has_method("pickup_item"):
		target_player.pickup_item(self, "TestButton")
		# Don't hide - will be positioned on player's head
		is_flying_to_player = false
		print("TestButton picked up!")
