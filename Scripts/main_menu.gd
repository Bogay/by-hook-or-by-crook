extends Control

@export var start_level : PackedScene
@onready var audio_player : AudioStreamPlayer = $startAudio
@onready var button_hover : AudioStreamPlayer = $buttonHover

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_start_pressed() -> void:
	SceneManager.go_to_level(start_level)
	audio_player.play()

func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_start_mouse_entered() -> void:
	button_hover.play()
