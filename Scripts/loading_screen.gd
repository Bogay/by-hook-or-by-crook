extends Node2D

signal on_transition_finished

@onready var color_rect = $CanvasLayer/AnimationPlayer/ColorRect
@onready var animation_player = $CanvasLayer/AnimationPlayer

func _ready() -> void:
	color_rect.visible = false

func transition():
	color_rect.visible = true
	animation_player.play("fade_in")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fade_in":
		emit_signal("on_transition_finished")
		animation_player.play("fade_out")
	elif anim_name == "fade_out":
		color_rect.visible = false
