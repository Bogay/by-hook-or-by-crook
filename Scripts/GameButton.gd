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
	# Stop jellyfish behaviors
	var jellyfish = get_node_or_null("/root/BasicScene/Jellyfish")
	if jellyfish and jellyfish.has_method("stop_all_behaviors"):
		jellyfish.stop_all_behaviors()
		print("Jellyfish stopped!")
