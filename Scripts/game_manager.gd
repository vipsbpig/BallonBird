class_name GameManager
extends Node

# paths
const hitBoxPath : NodePath = ^"HitBoxArea"
const animPlayerPath : NodePath = ^"Mesh/AnimationPlayer"
const jumpParticlePath : NodePath = ^"JumpParticles"
const maxHealth : int = 1

@export_category("references")
@export var map_position : Node3D
@export var p1_position : Node3D
@export var p2_position : Node3D
@export var canvas : CanvasItem
@export var ready_go_player : AnimationPlayer
@export var win_player : AnimationPlayer
@export var win_bird_position : Node3D

@export_category("data")
@export var arena_datas : ArenaDatas
@export var ballon_data : BallonDatas

@export_category("groups")
@export var p1_group : String
@export var p2_group : String

@export_category("animations")
@export var fly_anim : String
@export var death_anim : String
@export var bump_anim : String
@export var dash_anim : String

@export_category("timers")
@export var slomoDuration : float
@export var deathDuration : float
@export var winDuration : float

@export_category("parameters")
@export var slomoSpeed : float
@export var attackSpeedThreshold : float
@export var redLineSpeed : float = 140
@export var wind : Vector3

# player runtime data
var p1_rigidBody : RigidBody3D
var p2_rigidBody : RigidBody3D

var p1_hitBox : Area3D
var p2_hitBox : Area3D

var p1_player : AnimationPlayer
var p2_player : AnimationPlayer

var p1_data : BirdConfig
var p2_data : BirdConfig

var p1_health : float
var p2_health : float

var p1_holdDuration : float
var p2_holdDuration : float

var p1_score : int = 0 : set = set_p1_score
var p2_score : int = 0 : set = set_p2_score

# global runtime data
var isFinished : bool = false
var slomoTimer : float = 0
var deathTimer : float = 0
var winTimer : float = 0

var hit_position : Vector2
var line_direction : Vector2

# signals
signal p1_score_change(score: int)
signal p2_score_change(score: int)

func set_p1_score(newscore: int):
	p1_score = newscore
	p1_score_change.emit(p1_score)

func set_p2_score(newscore: int):
	p2_score = newscore
	p2_score_change.emit(p2_score)

func _on_p1_area_entered(other: Area3D) -> void:
	if other.get_parent().is_in_group(p2_group):
		hit_position = get_viewport().get_camera_3d().unproject_position(other.get_parent().position)
		var hit_normal = other.position - p1_rigidBody.position
		line_direction = Vector2(hit_normal.y, -hit_normal.x)
		p2_health -= 1

func _on_p2_area_entered(other: Area3D) -> void:
	if other.get_parent().is_in_group(p1_group):
		hit_position = get_viewport().get_camera_3d().unproject_position(other.get_parent().position)
		var hit_normal = other.position - p2_rigidBody.position
		line_direction = Vector2(hit_normal.y, -hit_normal.x)
		p1_health -= 1

func _on_p1_body_entered(body: Node) -> void:
	if p1_health > 0:
		p1_player.play(bump_anim)
	
func _on_p2_body_entered(body: Node) -> void:
	if p2_health > 0:
		p2_player.play(bump_anim)

func _win() -> void:
	winTimer = winDuration
	var mesh : Node3D
	if p1_score == 2:
		mesh = ballon_data.Meshes[Global.p1_ballon_index].instantiate() as Node3D
	elif p2_score == 2:
		mesh = ballon_data.Meshes[Global.p2_ballon_index].instantiate() as Node3D		
	win_bird_position.add_child(mesh)
	mesh.transform.basis = Basis.IDENTITY
	mesh.transform.origin = Vector3.ZERO
	win_player.play("WIN")
	
func _ready() -> void:
	# map initialization
	var map_prefab = arena_datas.Arenas[Global.arena_index]
	var map = map_prefab.instantiate() as Node3D
	add_child(map)
	map.global_position = map_position.global_position
	
	# score reset
	p1_score = 0
	p2_score = 0

	# p1 initialization
	p1_data = ballon_data.Ballons[Global.p1_ballon_index]
	p1_rigidBody = p1_data.asset.instantiate() as RigidBody3D
	add_child(p1_rigidBody)
	p1_rigidBody.add_to_group(p1_group)
	p1_hitBox = p1_rigidBody.get_node(hitBoxPath) as Area3D
	p1_hitBox.area_entered.connect(_on_p1_area_entered)
	p1_player = p1_rigidBody.get_node(animPlayerPath) as AnimationPlayer

	# p2 initialization
	p2_data = ballon_data.Ballons[Global.p2_ballon_index]
	p2_rigidBody = p2_data.asset.instantiate() as RigidBody3D
	add_child(p2_rigidBody)
	p2_rigidBody.add_to_group(p2_group)
	p2_hitBox = p2_rigidBody.get_node(hitBoxPath) as Area3D
	p2_hitBox.area_entered.connect(_on_p2_area_entered)
	p2_player = p2_rigidBody.get_node(animPlayerPath) as AnimationPlayer
	# inverse
	p2_rigidBody.rotation_degrees.y += 180

	_reset_players()
	# setup bump anim
	p1_rigidBody.body_entered.connect(_on_p1_body_entered)
	p2_rigidBody.body_entered.connect(_on_p2_body_entered)
	canvas.draw.connect(_draw)

func _reset_players() -> void:
	isFinished = false
	_reset_player(p1_rigidBody, p1_data, p1_position.position)
	_reset_player(p2_rigidBody, p2_data, p2_position.position)
	p1_player.stop()
	p2_player.stop()
	p1_health = maxHealth
	p2_health = maxHealth
	ready_go_player.queue("Prompt")

func _reset_player(rigidBody: RigidBody3D, data: BirdConfig, position: Vector3) -> void:
	rigidBody.position = position
	rigidBody.rotation.z = 0
	rigidBody.linear_velocity = Vector3.ZERO
	rigidBody.angular_velocity = Vector3.ZERO
	rigidBody.gravity_scale = 0
	rigidBody.mass = data.mass
	rigidBody.constant_force = wind

	rigidBody.contact_monitor = true
	rigidBody.max_contacts_reported = 2

func _data_driven_anim(player: AnimationPlayer, health: int) -> void:
	if health > 0 && player.current_animation != dash_anim:
		player.play(fly_anim)

func _draw() -> void:
	if isFinished && slomoTimer > 0:
		canvas.draw_line(
			hit_position + line_direction * (slomoDuration - slomoTimer) * redLineSpeed,
			hit_position - line_direction * (slomoDuration - slomoTimer) * redLineSpeed,
			Color.RED,
			4)

func _process(delta: float) -> void:
	slomoTimer = max(0, slomoTimer - delta / Engine.time_scale)
	deathTimer = max(0, deathTimer - delta / Engine.time_scale)
	var prevWinTimer : float = winTimer
	winTimer = max(0, winTimer - delta / Engine.time_scale)

	if prevWinTimer > 0 && winTimer == 0:
		_switch_to_arena_selection()

	if ready_go_player.is_playing():
		return

	if isFinished:
		canvas.queue_redraw()

	if winTimer == 0 && (p1_score >= 2 || p2_score >= 2):
		_win()

	if deathTimer == 0 && isFinished && p1_score < 2 && p2_score < 2:
		_reset_players()

	Engine.time_scale = slomoSpeed if slomoTimer > 0 else 1
	if isFinished || p1_health > 0 && p2_health > 0:
		return

	if p1_health == 0:
		p1_player.play(death_anim)
		p1_rigidBody.gravity_scale = 1
		p2_score = p2_score + 1
		isFinished = true
		slomoTimer = slomoDuration
		deathTimer = deathDuration
		return

	if p2_health == 0:
		p2_player.play(death_anim)
		p2_rigidBody.gravity_scale = 1
		p1_score = p1_score + 1
		isFinished = true
		slomoTimer = slomoDuration
		deathTimer = deathDuration
		return

func _physics_process(delta: float) -> void:
	if ready_go_player.is_playing():
		return

	# if the game is finished, it shouldn't update anything
	if isFinished:
		return

	# process input for each player
	p1_holdDuration = process_input(
		p1_rigidBody,
		p1_hitBox,
		p1_player,
		p1_data,
		delta,
		p1_holdDuration,
		"move_left",
		"move_right",
		"jump")
	p2_holdDuration = process_input(
		p2_rigidBody,
		p2_hitBox,
		p2_player,
		p2_data,
		delta,
		p2_holdDuration,
		"move_right2",
		"move_left2",
		"jump2")
	
func process_input(
		rigidBody: RigidBody3D,
		hitBox: Area3D,
		animPlayer: AnimationPlayer,
		player: BirdConfig,
		delta: float,
		holdDuration: float,
		left_input: String,
		right_input: String,
		jump_input: String) -> float:
	hitBox.monitoring = rigidBody.linear_velocity.length() >= attackSpeedThreshold
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
		animPlayer.play(fly_anim)
		rigidBody.apply_torque_impulse(local_z_direction * player.torque * rotateDirection * delta)

	if Input.is_action_just_pressed(jump_input) && holdDuration > 0:
		rigidBody.apply_force(local_x_direction * player.jump_force)
		animPlayer.play(dash_anim)
		var particle = rigidBody.get_node(jumpParticlePath) as GPUParticles3D
		particle.emitting = true
		particle.restart()

	return holdDuration

func _switch_to_arena_selection():
	get_tree().change_scene_to_file("res://Scenes/UI/BallonSelection.tscn")
