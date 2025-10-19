extends Area2D

@export var hp_border: TextureRect
@export var hp_fill: TextureRect

var current_hp: float = 100.0
var max_hp: float = 100.0
var base_scale: Vector2

var is_flying_to_player: bool = false
var target_player: Node = null
const FLY_SPEED: float = 800.0

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
	print("HPBar placed on ground at: ", global_position)
