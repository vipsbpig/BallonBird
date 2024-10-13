extends Node

@export var rigidBody : RigidBody3D

@export var moveSpeed : float = 5
@export var jumpForce : float = 1

var fixedDeltaTime : float = 0

func _physics_process(delta: float) -> void:
	fixedDeltaTime = delta	
	
	var velocity : Vector3 = rigidBody.linear_velocity
	var moveDirection : int = 0;
	if Input.is_action_pressed("move_left"):
		moveDirection = -1
	elif Input.is_action_pressed("move_right"):
		moveDirection = 1
	
	if moveDirection != 0: velocity.x = moveSpeed * moveDirection 

	rigidBody.linear_velocity = velocity	
		
	if Input.is_action_just_pressed("jump"):
		rigidBody.apply_force(Vector3(0, jumpForce, 0))
