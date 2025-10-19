extends CharacterBody2D

@export var magic_attack_scene: PackedScene
@export var attack_cooldown: float = 1.0
@export var attack_damage: float = 22.0
@onready var spawn_attack = $SpawnAttack

func _ready() -> void:
	var attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_perform_magic_attack)
	add_child(attack_timer)
	attack_timer.start()

func _perform_magic_attack() -> void:
	print("Magic Jellyfish performing magic attack")
	var magic_attack = magic_attack_scene.instantiate()
	var random_up_velocity = Vector2(randf_range(-3, 3), randf_range(-10, -30))
	magic_attack.velocity = random_up_velocity
	magic_attack.scale = Vector2(0.5, 0.5)
	spawn_attack.add_child(magic_attack)
