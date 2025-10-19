extends RigidBody2D

@onready var btn: Button = $Button

func _ready() -> void:
	btn.pressed.connect(_on_button_pressed)
	body_entered.connect(_on_body_entered)

	# Make it a floating platform (no gravity)
	gravity_scale = 0.0
	freeze = true  # Static platform

func _on_body_entered(body: Node) -> void:
	print("GameButton hit by: ", body.name)

func _on_button_pressed():
	_stop_jellyfish()

func on_hit_by_spear():
	btn.text = "Hit!"
	_stop_jellyfish()

func _stop_jellyfish():
	# Stop jellyfish behaviors - find jellyfish in scene
	var jellyfish = get_tree().get_first_node_in_group("Jellyfish")
	if jellyfish and jellyfish.has_method("stop_all_behaviors"):
		jellyfish.stop_all_behaviors()
		print("Jellyfish stopped!")
