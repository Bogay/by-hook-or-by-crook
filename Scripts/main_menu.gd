extends Control

@export var start_level : PackedScene
# @export var loading_screen : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_start_pressed() -> void:
	SceneManager.go_to_level(start_level)

func _on_exit_pressed() -> void:
	get_tree().quit()
