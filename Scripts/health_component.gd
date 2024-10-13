class_name HealthComponent
extends Node

@export var MAX_HEALTH = 1

var health : float = 0

func _ready() -> void:
	health = MAX_HEALTH
