extends Control

func _ready() -> void:
	var restart_button = $VBoxContainer/MarginContainer/RestartButton
	restart_button.pressed.connect(_on_restart_pressed)

func _on_restart_pressed() -> void:
	# Restart the current level using GameState
	var current_level_path = GameState.current_level
	get_tree().change_scene_to_file(current_level_path)
