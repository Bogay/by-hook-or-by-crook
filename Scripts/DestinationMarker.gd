extends Area2D

@export var next_scene_path: String = "res://Scenes/level_02.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		_switch_scene()

func _switch_scene() -> void:
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
