class_name GameManager
extends Node

@export var p1_position : Node3D
@export var p2_position : Node3D

# references
var p1_rigidBody : RigidBody3D
var p2_rigidBody : RigidBody3D

var p1_hitBox : Area3D
var p2_hitBox : Area3D

# config
@export var p1_group : String
@export var p2_group : String

@export var p1_data : BirdConfig
@export var p2_data : BirdConfig

@export var p1_mat : StandardMaterial3D
@export var p2_mat : StandardMaterial3D

@export var attackSpeedThreshold : float

# runtime
var p1_health : float
var p2_health : float

var p1_holdDuration : float
var p2_holdDuration : float

var prefabPath : String = "res://Ballons/Mock/MockBallon.tscn"
var hitBoxPath : NodePath = ^"HitBox"

var isFinished : bool = false

func _ready() -> void:

	# p1 initialization
	p1_rigidBody = load(prefabPath).instantiate() as RigidBody3D
	p1_rigidBody.position = p1_position.position
	add_child(p1_rigidBody)

	p1_hitBox = p1_rigidBody.get_node(hitBoxPath) as Area3D

	p1_health = p1_data.maxHealth
	p1_hitBox.area_entered.connect(_on_p1_area_entered)
	p1_rigidBody.add_to_group(p1_group)
	for child in p1_rigidBody.get_children():
		if child is MeshInstance3D:
			child.set_surface_override_material(0, p1_mat)

	# p2 initialization
	p2_rigidBody = load(prefabPath).instantiate() as RigidBody3D
	p2_rigidBody.position = p2_position.position
	add_child(p2_rigidBody)

	p2_hitBox = p2_rigidBody.get_node(hitBoxPath) as Area3D

	p2_health = p2_data.maxHealth
	p2_hitBox.area_entered.connect(_on_p2_area_entered)
	p2_rigidBody.add_to_group(p2_group)
	for child in p2_rigidBody.get_children():
		if child is MeshInstance3D:
			child.set_surface_override_material(0, p2_mat)

func _on_p1_area_entered(other: Area3D) -> void:
	if other.get_parent().is_in_group(p2_group):
		p2_health -= 1

func _on_p2_area_entered(other: Area3D) -> void:
	if other.get_parent().is_in_group(p1_group):
		p1_health -= 1

func _process(_delta: float) -> void:
	if isFinished || p1_health > 0 && p2_health > 0:
		return
	if p1_health == 0:
		print("p1 is defeated!")
		isFinished = true
		return
	if p2_health == 0:
		print("p2 is defeated!")
		isFinished = true
		return

func _physics_process(delta: float) -> void:
	# if the game is finished, it shouldn't update anything
	if isFinished:
		return

	# if the linear velocity of each player is slower than threshold, it shouldn't attack
	p1_hitBox.monitoring = p1_rigidBody.linear_velocity.length() >= attackSpeedThreshold
	p2_hitBox.monitoring = p2_rigidBody.linear_velocity.length() >= attackSpeedThreshold

	# process input for each player
	p1_holdDuration = process_input(
		p1_rigidBody,
		p1_data,
		delta,
		p1_holdDuration,
		"move_left",
		"move_right",
		"jump");
	p2_holdDuration = process_input(
		p2_rigidBody,
		p2_data, delta,
		p2_holdDuration,
		"move_left2",
		"move_right2",
		"jump2");
	
func process_input(
		rigidBody: RigidBody3D,
		player: BirdConfig,
		delta: float,
		holdDuration: float,
		left_input: String,
		right_input: String,
		jump_input: String) -> float:
	var velocity : Vector3 = rigidBody.angular_velocity
	var rotateDirection : int = 0
	
	if Input.is_action_pressed(left_input):
		rotateDirection = 1
	elif Input.is_action_pressed(right_input):
		rotateDirection = -1

	if Input.is_action_just_pressed(left_input) || Input.is_action_just_pressed(right_input):
		holdDuration = player.rotateTime

	holdDuration -= delta

	if rotateDirection != 0 && holdDuration > 0:
		velocity.z = player.rotateSpeed * rotateDirection * delta
	else:
		velocity.z = lerp(velocity.z, 0.0, player.rotaionDampForce * delta)

	rigidBody.angular_velocity = velocity

	if Input.is_action_just_pressed(jump_input):
		var local_x_direction = rigidBody.transform.basis.x
		rigidBody.apply_force(local_x_direction * player.jumpForce)

	return holdDuration
