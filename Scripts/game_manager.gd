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
@export var ready_go_player : AnimationPlayer
@export var win_player : AnimationPlayer
@export var win_bird_position : Node3D
@export var audio_player1 : AudioStreamPlayer
@export var audio_player2 : AudioStreamPlayer
@export var generic_player : AudioStreamPlayer

@export_category("particles")
@export var killVfx : GPUParticles3D
@export var hitBeakVfx : GPUParticles3D
@export var bumpVfx : GPUParticles3D
@export var p1WallVfx : GPUParticles3D
@export var p2WallVfx : GPUParticles3D

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
@export var attackMomentum : float = 3
@export var attackInertia : float = 3
@export var redLineSpeed : float = 140
@export var wind : Vector3
@export var spikeIndex : int = 3

@export_category("sfx")
@export var farts : Array[AudioStream]
@export var flaps : Array[AudioStream]
@export var swords : Array[AudioStream]
@export var impacts : Array[AudioStream]
@export var kill_sound : AudioStream

# player runtime data
var p1_rigidBody : RigidBody3D
var p2_rigidBody : RigidBody3D

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

var random = RandomNumberGenerator.new()

# signals
signal p1_score_change(score: int)
signal p2_score_change(score: int)

func set_p1_score(newscore: int):
	p1_score = newscore
	p1_score_change.emit(p1_score)

func set_p2_score(newscore: int):
	p2_score = newscore
	p2_score_change.emit(p2_score)

func _on_p1_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	var rb = p1_rigidBody
	var anim_player = p1_player
	var audio_player = audio_player1
	var wallVfx = p1WallVfx
	var momentum = rb.linear_velocity.length() * rb.mass
	var inertia = abs(rb.angular_velocity.z * rb.inertia.z)
	var state: PhysicsDirectBodyState3D = PhysicsServer3D.body_get_direct_state(rb.get_rid())
	var num_contacts = state.get_contact_count()
	print("p1: momentum: %f; inertia: %f" % [momentum, inertia])

	var index = 0
	for n in num_contacts:
		var rid: RID = state.get_contact_collider(n)
		var shape_index = state.get_contact_collider_shape(n)
		if rid == body_rid && shape_index == body_shape_index:
			index = n

	var contact_point = state.get_contact_collider_position(index)
	var contact_normal = state.get_contact_local_normal(index)

	var local_shape = rb.shape_owner_get_owner(rb.shape_find_owner(local_shape_index))

	if p1_health == 0:
		return

	if body is GridMap:
		var grid = body
		var grid_pos = grid.local_to_map(grid.to_local(contact_point - contact_normal * 0.1))
		grid_pos.z = 0
		print("p1: contact point is ", contact_point, "contact normal is ", contact_normal, "grid position is ", grid_pos)
		var item = grid.get_cell_item(grid_pos)
		if item == spikeIndex && local_shape.name == "Body" && (momentum > attackMomentum || inertia > attackInertia):
			generic_player.stream = kill_sound
			generic_player.play()
			_play_vfx(killVfx, contact_point)
			p1_health -= 1
		elif item != GridMap.INVALID_CELL_ITEM:
			audio_player.stream = impacts[random.randi_range(0, impacts.size() - 1)]
			audio_player.play()
			_play_vfx(wallVfx, contact_point)
		return

	var other_shape = body.shape_owner_get_owner(body.shape_find_owner(body_shape_index))

	if local_shape.name == "Body":
		anim_player.play(bump_anim)

	if body.name == "Collision":
		audio_player.stream = impacts[random.randi_range(0, impacts.size() - 1)]
		audio_player.play()
		_play_vfx(wallVfx, contact_point)
		return

	if p2_health == 0:
		return

	if local_shape.name == "Beak" && other_shape.name == "Body" && other_shape.get_parent().is_in_group(p2_group):
		if momentum > attackMomentum || inertia > attackInertia:
			generic_player.stream = kill_sound
			generic_player.play()
			_play_vfx(killVfx, contact_point)
			p2_health -= 1
		else:
			generic_player.stream = impacts[random.randi_range(0, impacts.size() - 1)]
			generic_player.play()
			_play_vfx(bumpVfx, contact_point)
	elif local_shape.name == "Beak" && other_shape.name == "Beak":
		print("beak colliding!")
		generic_player.stream = swords[random.randi_range(0, swords.size() - 1)]
		generic_player.play()
		_play_vfx(hitBeakVfx, contact_point)
	elif local_shape.name == "Body" && other_shape.name == "Body":
		generic_player.stream = impacts[random.randi_range(0, impacts.size() - 1)]
		generic_player.play()
		_play_vfx(bumpVfx, contact_point)

func _on_p2_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	var rb = p2_rigidBody
	var anim_player = p2_player
	var audio_player = audio_player2
	var wallVfx = p2WallVfx
	var momentum = rb.linear_velocity.length() * rb.mass
	var inertia = abs(rb.angular_velocity.z * rb.inertia.z)
	var state: PhysicsDirectBodyState3D = PhysicsServer3D.body_get_direct_state(rb.get_rid())
	var num_contacts = state.get_contact_count()
	print("p2: momentum: %f; inertia: %f" % [momentum, inertia])

	var index = 0
	for n in num_contacts:
		var rid: RID = state.get_contact_collider(n)
		var shape_index = state.get_contact_collider_shape(n)
		if rid == body_rid && shape_index == body_shape_index:
			index = n

	var contact_point = state.get_contact_collider_position(index)
	var contact_normal = state.get_contact_local_normal(index)

	var local_shape = rb.shape_owner_get_owner(rb.shape_find_owner(local_shape_index))

	if p2_health == 0:
		return

	if body is GridMap:
		var grid = body
		var grid_pos = grid.local_to_map(grid.to_local(contact_point - contact_normal * 0.1))
		grid_pos.z = 0
		print("p2: contact point is ", contact_point, "contact normal is ", contact_normal, "grid position is ", grid_pos)
		var item = grid.get_cell_item(grid_pos)
		if item == spikeIndex && local_shape.name == "Body" && (momentum > attackMomentum || inertia > attackInertia):
			generic_player.stream = kill_sound
			generic_player.play()
			_play_vfx(killVfx, contact_point)
			p2_health -= 1
		elif item != GridMap.INVALID_CELL_ITEM:
			audio_player.stream = impacts[random.randi_range(0, impacts.size() - 1)]
			audio_player.play()
			_play_vfx(wallVfx, contact_point)
		return

	var other_shape = body.shape_owner_get_owner(body.shape_find_owner(body_shape_index))

	if local_shape.name == "Body":
		anim_player.play(bump_anim)

	if body.name == "Collision":
		audio_player.stream = impacts[random.randi_range(0, impacts.size() - 1)]
		audio_player.play()
		_play_vfx(wallVfx, contact_point)
		return

	if p1_health == 0:
		return

	if local_shape.name == "Beak" && other_shape.name == "Body" && other_shape.get_parent().is_in_group(p1_group):
		if momentum > attackMomentum || inertia > attackInertia:
			generic_player.stream = kill_sound
			generic_player.play()
			_play_vfx(killVfx, contact_point)
			p1_health -= 1
		else:
			generic_player.stream = impacts[random.randi_range(0, impacts.size() - 1)]
			generic_player.play()
			_play_vfx(bumpVfx, contact_point)

func _play_vfx(p: GPUParticles3D, position: Vector3) -> void:
	p.global_position = position
	p.emitting = true
	for child in p.get_children():
		if child is GPUParticles3D:
			child.emitting = true

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
	var music_path = "res://Audio/music/mus_map%d.ogg" % (Global.arena_index + 1)
	Global.play_bgm(load(music_path))
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
	p1_rigidBody.body_shape_entered.connect(_on_p1_body_shape_entered)
	p1_player = p1_rigidBody.get_node(animPlayerPath) as AnimationPlayer

	# p2 initialization
	p2_data = ballon_data.Ballons[Global.p2_ballon_index]
	p2_rigidBody = p2_data.asset.instantiate() as RigidBody3D
	add_child(p2_rigidBody)
	p2_rigidBody.add_to_group(p2_group)
	p2_rigidBody.body_shape_entered.connect(_on_p2_body_shape_entered)
	p2_player = p2_rigidBody.get_node(animPlayerPath) as AnimationPlayer
	# inverse
	p2_rigidBody.rotation_degrees.y += 180

	_reset_players()

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
	rigidBody.inertia = Vector3(0, 0, data.inertia)
	rigidBody.constant_force = wind

	rigidBody.contact_monitor = true
	rigidBody.max_contacts_reported = 4

func _data_driven_anim(player: AnimationPlayer, health: int) -> void:
	if health > 0 && player.current_animation != dash_anim:
		player.play(fly_anim)

func _process(delta: float) -> void:
	slomoTimer = max(0, slomoTimer - delta / Engine.time_scale)
	deathTimer = max(0, deathTimer - delta / Engine.time_scale)
	var prevWinTimer : float = winTimer
	winTimer = max(0, winTimer - delta / Engine.time_scale)

	if ready_go_player.is_playing():
		return

	if prevWinTimer > 0 && winTimer == 0:
		_switch_to_arena_selection()

	if deathTimer == 0 && isFinished && p1_score < 2 && p2_score < 2:
		_reset_players()
		
	if winTimer == 0 && (p1_score >= 2 || p2_score >= 2):
		_win()

	Engine.time_scale = slomoSpeed if slomoTimer > 0 && slomoTimer < slomoDuration - 0.1 else 1
	if isFinished:
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
		audio_player1,
		p1_player,
		p1_data,
		delta,
		p1_holdDuration,
		"move_left",
		"move_right",
		"jump")
	p2_holdDuration = process_input(
		p2_rigidBody,
		audio_player2,
		
		p2_player,
		p2_data,
		delta,
		p2_holdDuration,
		"move_right2",
		"move_left2",
		"jump2")
	
func process_input(
		rigidBody: RigidBody3D,
		audio_player: AudioStreamPlayer,
		animPlayer: AnimationPlayer,
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
		animPlayer.play(fly_anim)
		audio_player.stream = flaps[random.randi_range(0, flaps.size() - 1)]
		audio_player.play()
		rigidBody.apply_torque_impulse(local_z_direction * player.torque * rotateDirection * delta)

	if Input.is_action_just_pressed(jump_input) && holdDuration > 0:
		rigidBody.apply_force(local_x_direction * player.jump_force)
		animPlayer.play(dash_anim)
		audio_player.stream = farts[random.randi_range(0, farts.size() - 1)]
		audio_player.play()
		var particle = rigidBody.get_node(jumpParticlePath) as GPUParticles3D
		particle.emitting = true
		particle.restart()

	return holdDuration

func _switch_to_arena_selection():
	get_tree().change_scene_to_file("res://Scenes/UI/BallonSelection.tscn")
	Global.play_bgm(load("res://Audio/music/mus_main.ogg"))
