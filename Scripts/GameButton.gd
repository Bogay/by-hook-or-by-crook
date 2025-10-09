extends Area2D

@onready var btn: Button = $Button

func _ready() -> void:
	body_entered.connect(_body_entered)
	body_entered.connect(func(_body): btn.text = "Triggered")
	btn.pressed.connect(func(): btn.text = "Test")

func _body_entered(body):
	print("Hello")
