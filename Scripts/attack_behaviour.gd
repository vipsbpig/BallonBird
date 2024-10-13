extends Node

@export var rigidBody : RigidBody3D
@export var hitBox : Area3D
@export var hurtBox : HurtBox

@export var damage : float = 1
@export var enableSpeed : float = 4

func _ready() -> void:
	hitBox.area_entered.connect(_on_area_entered)
	hitBox.monitoring = false

func _physics_process(delta: float) -> void:
	var speed = rigidBody.linear_velocity.length()
	hitBox.monitoring = speed >= enableSpeed
	
func _on_area_entered(other: HurtBox):
	if other!=null && other != hurtBox:
		other.deal_damage(damage)
	
