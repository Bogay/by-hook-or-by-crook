extends Node2D

func _ready() -> void:
	$DebugBackground.free()

func _process(delta: float) -> void:
	var cam = get_tree().get_first_node_in_group("camera") as Camera2D
	if cam == null:
		return
	global_position = cam.get_screen_center_position()
