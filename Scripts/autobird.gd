class_name AutoBird
extends Node

const animPlayerPath : NodePath = ^"Mesh/AnimationPlayer"

@export var birds : Array[RigidBody3D]
@export var width : Vector2
@export var height : Vector2
@export var speedRange : Vector2
@export var angularSpeedRange : Vector2

var rng = RandomNumberGenerator.new()

func _ready():
	for bird in birds:
		bird.position.x = rng.randf_range(width.x, width.y)
		bird.position.y = rng.randf_range(height.x, height.y)
		(bird.get_node(animPlayerPath) as AnimationPlayer).play("Fly1")
		bird.linear_velocity = Vector3(rng.randf(), rng.randf(), 0).normalized() * rng.randf_range(speedRange.x, speedRange.y)
		bird.angular_velocity = Vector3(0, 0, rng.randf_range(angularSpeedRange.x, angularSpeedRange.y))
		bird.physics_material_override.friction = 0
		bird.physics_material_override.bounce = 1
