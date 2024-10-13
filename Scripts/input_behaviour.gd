extends Node

@export var rigidBody : RigidBody3D

@export var maxSpeed : float = 12
@export var rotateSpeed : float = 5
@export var jumpForce : float = 1
@export var rotaionDampForce : float = 10

var fixedDeltaTime : float = 0

func _physics_process(delta: float) -> void:
	fixedDeltaTime = delta	
	
	var velocity : Vector3 = rigidBody.angular_velocity
	var moveDirection : int = 0;
	if Input.is_action_pressed("move_left"):
		moveDirection = 1
	elif Input.is_action_pressed("move_right"):
		moveDirection = -1
	
	if moveDirection != 0: velocity.z = rotateSpeed * moveDirection * delta
	else: velocity.z = lerp(velocity.z, 0.0, rotaionDampForce * fixedDeltaTime)

	rigidBody.angular_velocity = velocity
		
	if Input.is_action_just_pressed("jump"):
		var local_x_direction = rigidBody.transform.basis.x
		rigidBody.apply_force(local_x_direction * jumpForce)
		
	# 计算速度的大小
	var current_velocity = rigidBody.linear_velocity
	var speed = current_velocity.length()
	# 检查是否超过最大速度
	if speed > maxSpeed:
		# 计算限制后的速度向量
		var limited_velocity = current_velocity.normalized() * maxSpeed
		# 设置刚体的线性速度为限制后的速度
		rigidBody.linear_velocity = limited_velocity
