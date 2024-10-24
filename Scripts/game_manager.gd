class_name GameManager
extends Node

@export var map_position : Node3D
@export var p1_position : Node3D
@export var p2_position : Node3D

# references
var p1_rigidBody : RigidBody3D
var p2_rigidBody : RigidBody3D

var p1_hitBox : Area3D
var p2_hitBox : Area3D

var p1_player : AnimationPlayer
var p2_player : AnimationPlayer

# config
@export var arena_datas : ArenaDatas

@export var p1_group : String
@export var p2_group : String

@export var fly_anim : String
@export var death_anim : String

@export var ballon_data : BallonDatas

@export var slomoDuration : float
@export var slomoSpeed : float
@export var attackSpeedThreshold : float
@export var wind : Vector3

# runtime
var p1_data : BirdConfig
var p2_data : BirdConfig

var p1_health : float
var p2_health : float

var p1_holdDuration : float
var p2_holdDuration : float

const hitBoxPath : NodePath = ^"HitBoxArea"
const animPlayerPath : NodePath = ^"Mesh/AnimationPlayer"
const jumpParticlePath : NodePath = ^"JumpParticles"
const maxHealth : int = 1

var isFinished : bool = false
var slomoTimer : float = 0

func _ready() -> void:
	# map initialization
	var map_prefab = arena_datas.Arenas[Global.arena_index]
	var map = map_prefab.instantiate() as Node3D
	add_child(map)
	map.global_position = map_position.global_position

	# p1 initialization
	p1_data = ballon_data.Ballons[Global.p1_ballon_index]
	p1_rigidBody = p1_data.asset.instantiate() as RigidBody3D
	add_child(p1_rigidBody)
	p1_rigidBody.position = p1_position.position
	p1_rigidBody.constant_force = wind
	p1_rigidBody.mass = p1_data.mass

	p1_hitBox = p1_rigidBody.get_node(hitBoxPath) as Area3D
	
	p1_player = p1_rigidBody.get_node(animPlayerPath) as AnimationPlayer
	p1_player.play(fly_anim)

	p1_health = maxHealth
	p1_hitBox.area_entered.connect(_on_p1_area_entered)
	p1_rigidBody.add_to_group(p1_group)

	# p2 initialization
	p2_data = ballon_data.Ballons[Global.p2_ballon_index]
	p2_rigidBody = p2_data.asset.instantiate() as RigidBody3D
	# inverse
	p2_rigidBody.rotation_degrees.y += 180
	add_child(p2_rigidBody)
	p2_rigidBody.position = p2_position.position
	p2_rigidBody.constant_force = wind
	p2_rigidBody.mass = p2_data.mass

	p2_hitBox = p2_rigidBody.get_node(hitBoxPath) as Area3D
	
	p2_player = p2_rigidBody.get_node(animPlayerPath) as AnimationPlayer
	p2_player.play("Fly1")

	p2_health = maxHealth
	p2_hitBox.area_entered.connect(_on_p2_area_entered)
	p2_rigidBody.add_to_group(p2_group)

func _on_p1_area_entered(other: Area3D) -> void:
	if other.get_parent().is_in_group(p2_group):
		p2_health -= 1

func _on_p2_area_entered(other: Area3D) -> void:
	if other.get_parent().is_in_group(p1_group):
		p1_health -= 1

func _process(delta: float) -> void:
	slomoTimer = max(0, slomoTimer - delta / Engine.time_scale)
	if slomoTimer > 0:
		Engine.time_scale = slomoSpeed
	else:
		Engine.time_scale = 1

	if isFinished || p1_health > 0 && p2_health > 0:
		return

	if p1_health == 0:
		print("p1 is defeated!")
		isFinished = true
		p1_player.play(death_anim)
		slomoTimer = slomoDuration
		return

	if p2_health == 0:
		print("p2 is defeated!")
		isFinished = true
		p2_player.play(death_anim)
		slomoTimer = slomoDuration
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
		"jump")
	p2_holdDuration = process_input(
		p2_rigidBody,
		p2_data, delta,
		p2_holdDuration,
		"move_right2",
		"move_left2",
		"jump2")
	
func process_input(
		rigidBody: RigidBody3D,
		player: BirdConfig,
		delta: float,
		holdDuration: float,
		left_input: String,
		right_input: String,
		jump_input: String) -> float:
	var rotateDirection : int = 0
	
	if Input.is_action_pressed(left_input):
		rotateDirection = 1
	elif Input.is_action_pressed(right_input):
		rotateDirection = -1

	if Input.is_action_just_pressed(left_input) || Input.is_action_just_pressed(right_input) || Input.is_action_just_pressed(jump_input):
		holdDuration = player.rotate_time

	holdDuration -= delta

	rigidBody.linear_damp = player.linear_damp
	rigidBody.angular_damp = player.angular_damp

	var local_x_direction = rigidBody.transform.basis.x
	var local_z_direction = rigidBody.transform.basis.z

	if rotateDirection != 0 && holdDuration > 0:
		rigidBody.apply_torque_impulse(local_z_direction * player.torque * rotateDirection * delta)

	if Input.is_action_just_pressed(jump_input) && holdDuration > 0:
		rigidBody.apply_force(local_x_direction * player.jump_force)
		var particle = rigidBody.get_node(jumpParticlePath) as GPUParticles3D
		particle.emitting = true
		particle.restart()

	return holdDuration
