extends Node2D

func _ready() -> void:
	$DebugBackground.free()

	# Connect player HP to HP bar - find player in current scene
	var player = get_tree().get_first_node_in_group("Player")
	if player == null:
		# Try finding in sibling nodes
		player = get_parent().get_node_or_null("Player")

	var hp_bar = $ScreenUI/HPBar
	if player and hp_bar:
		player.hp_changed.connect(_on_player_hp_changed)
		hp_bar.set_max_hp(player.max_hp)
		hp_bar.set_hp(player.current_hp)

func _on_player_hp_changed(new_hp: float) -> void:
	var hp_bar = $ScreenUI/HPBar
	if hp_bar:
		hp_bar.set_hp(new_hp)

func _process(delta: float) -> void:
	var cam = get_tree().get_first_node_in_group("camera") as Camera2D
	if cam == null:
		return
	global_position = cam.get_screen_center_position()
