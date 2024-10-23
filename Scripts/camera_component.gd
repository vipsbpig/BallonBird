extends Node

@export var followTarget : Node3D
# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	if Global.CameraContoller != null:
		Global.CameraContoller.AppendFollow(followTarget)
	
func _exit_tree() -> void:
	if Global.CameraContoller != null:
		Global.CameraContoller.EraseFollow(followTarget)
