extends Control

func _ready() -> void:
	var restart_button = $VBoxContainer/MarginContainer/RestartButton
	restart_button.pressed.connect(_on_restart_pressed)

func _on_restart_pressed() -> void:
	# Restart from level 1
	get_tree().change_scene_to_file("res://Scenes/level_01.tscn")
