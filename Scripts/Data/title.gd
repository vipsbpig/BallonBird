extends Node3D

@export var title_animPlayer : AnimationPlayer
@export var ballonScene : PackedScene

func _ready():
	title_animPlayer.play("logoAction")
	var stream = load("res://Audio/music/mus_main.ogg")
	Global.play_bgm(stream)

func _process(delta: float):
	if Input.is_action_pressed("jump") || Input.is_action_pressed("jump2"):
		get_tree().change_scene_to_packed(ballonScene)
