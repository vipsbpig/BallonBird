class_name CameraController
extends Node

@export var pCam : PhantomCamera3D
@export var distanc_min_max : Vector2

func _enter_tree() -> void:
	Global.CameraContoller = self
	
func _ready() -> void:
	pCam.set_auto_follow_distance(true)
	pCam.set_auto_follow_distance_min(distanc_min_max.x)
	pCam.set_auto_follow_distance_max(distanc_min_max.y)
	#pass
	#pCam.set_auto_follow_distance(4)

func AppendFollow(follow: Node3D)->void:
	pCam.append_follow_targets(follow)
	
func EraseFollow(follow: Node3D)->void:
	pCam.erase_follow_targets(follow)
