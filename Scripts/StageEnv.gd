extends Node2D

@onready var follow = $FollowCamera

@export var clouds: Array[Texture2D]
@export var cloud_spawn_interval: float = 3.0
@export var cloud_speed_min: float = 20.0
@export var cloud_speed_max: float = 50.0
@export var cloud_scale_min: float = 0.3
@export var cloud_scale_max: float = 0.8
@export var spawn_height_min: float = -150.0
@export var spawn_height_max: float = 300.0
@export var cloud_lifetime: float = 15.0

var spawn_timer: Timer
var screen_size: Vector2

func _ready():
	# Set up screen size
	screen_size = get_viewport().get_visible_rect().size

func _spawn_cloud():
	if clouds.is_empty():
		return
	
	var cam = get_tree().get_first_node_in_group("camera") as Camera2D
	if cam == null:
		return
	
	# Select random cloud texture
	var cloud_texture = clouds[randi() % clouds.size()]
	
	# Create cloud sprite
	var cloud_sprite = Sprite2D.new()
	cloud_sprite.texture = cloud_texture
	
	# Random scale
	var scale_factor = randf_range(cloud_scale_min, cloud_scale_max)
	cloud_sprite.scale = Vector2(scale_factor, scale_factor)
	
	# Get camera position and screen size for proper positioning
	var cam_pos = cam.get_screen_center_position()
	var spawn_x = cam_pos.x - screen_size.x / 2 - cloud_texture.get_width() * scale_factor
	var spawn_y = cam_pos.y + randf_range(spawn_height_min, spawn_height_max)
	cloud_sprite.global_position = Vector2(spawn_x, spawn_y)
	
	# Random speed
	var speed = randf_range(cloud_speed_min, cloud_speed_max)
	cloud_sprite.set_meta("speed", speed)
	
	# Set z-index to be behind background but visible
	cloud_sprite.z_index = -80
	
	add_child(cloud_sprite)
	
	# Set up lifetime timer
	var lifetime_timer = Timer.new()
	lifetime_timer.wait_time = cloud_lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(func(): if cloud_sprite and is_instance_valid(cloud_sprite): cloud_sprite.queue_free())
	cloud_sprite.add_child(lifetime_timer)
	lifetime_timer.start()

func _process(_delta: float) -> void:
	var cam = get_tree().get_first_node_in_group("camera") as Camera2D
	if cam == null:
		return

	follow.global_position = cam.get_screen_center_position()
	
	# Move clouds and clean up off-screen ones
	var cam_pos = cam.get_screen_center_position()
	for child in get_children():
		if child is Sprite2D and child != follow and child.has_meta("speed"):
			var cloud_sprite = child as Sprite2D
			var speed = cloud_sprite.get_meta("speed") as float
			cloud_sprite.global_position.x += speed * _delta
			
			# Remove clouds that have moved off-screen to the right
			var right_edge = cam_pos.x + screen_size.x / 2 + cloud_sprite.texture.get_width() * cloud_sprite.scale.x
			if cloud_sprite.global_position.x > right_edge:
				cloud_sprite.queue_free()
