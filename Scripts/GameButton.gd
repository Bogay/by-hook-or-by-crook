extends Area2D

@onready var btn: Button = $Button

func _ready() -> void:
	body_entered.connect(_body_entered)
	body_entered.connect(func(_body): btn.text = "Triggered")
	btn.pressed.connect(_on_button_pressed)

func _body_entered(body):
	print("Hello")

func _on_button_pressed():
	btn.text = "Test"
	# Stop jellyfish behaviors - find jellyfish in scene
	var jellyfish = get_tree().get_first_node_in_group("Jellyfish")
	if jellyfish == null:
		# Try finding in sibling nodes
		jellyfish = get_parent().get_parent().get_node_or_null("Jellyfish")

	if jellyfish and jellyfish.has_method("stop_all_behaviors"):
		jellyfish.stop_all_behaviors()
		print("Jellyfish stopped!")
