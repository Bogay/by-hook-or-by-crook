extends Node2D

var start_pos: Vector2
var end_pos: Vector2
var duration: float = 0.5
var elapsed: float = 0.0

func setup(from: Vector2, to: Vector2) -> void:
	start_pos = from
	end_pos = to

	# Position at the midpoint between start and end
	global_position = (from + to) / 2.0

	# Calculate the rotation to point towards the target
	var direction = (to - from).normalized()
	rotation = direction.angle()

	# Calculate the distance and scale the sprite accordingly
	var distance = from.distance_to(to)
	var sprite = $Sprite2D
	if sprite and sprite.texture:
		# Check if texture is taller than it is wide (vertical sprite)
		var texture_width = sprite.texture.get_width()
		var texture_height = sprite.texture.get_height()

		if texture_height > texture_width:
			# Sprite is vertical, rotate it 90 degrees and stretch along Y-axis
			sprite.rotation = PI / 2.0  # 90 degrees
			sprite.scale.y = distance / texture_height
			sprite.scale.x = 1.0  # Keep width at original size
		else:
			# Sprite is horizontal, stretch along X-axis
			sprite.scale.x = distance / texture_width
			sprite.scale.y = 1.0  # Keep height at original size

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
