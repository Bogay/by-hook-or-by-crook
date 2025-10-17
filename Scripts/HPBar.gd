extends Control

@onready var hp_fill: TextureRect = $HPFill
@onready var hp_border: TextureRect = $HPBorder

var max_hp: float = 100.0
var current_hp: float = 100.0
var base_scale: Vector2

func _ready() -> void:
	# Store the initial scale from the scene
	base_scale = hp_fill.scale
	update_hp_bar()

func set_hp(value: float) -> void:
	current_hp = clamp(value, 0.0, max_hp)
	update_hp_bar()

func set_max_hp(value: float) -> void:
	max_hp = value
	current_hp = clamp(current_hp, 0.0, max_hp)
	update_hp_bar()

func update_hp_bar() -> void:
	if hp_fill and hp_border:
		var hp_ratio = current_hp / max_hp if max_hp > 0 else 0.0
		# Multiply HP ratio by the base scale to respect the initial width
		hp_fill.scale.x = base_scale.x * hp_ratio
