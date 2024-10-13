class_name HurtBox
extends Area3D

@export var healthComponent : HealthComponent

func deal_damage(damage: float) -> void:
	healthComponent.health -= damage
	print("remain health:", healthComponent.health)
