class_name SpatialAudioPool
extends Node

var pool = []
var max_pool_size = 10 # 根据需求调整

func _ready():
	for i in range(max_pool_size):
		var audio_player = AudioStreamPlayer3D.new()
		add_child(audio_player)
		pool.append(audio_player)
		audio_player.stop() # 初始状态停止播放

func play_sound_at_position(sound: AudioStream, position: Vector3):
	var audio_player = get_free_audio_player()
	if audio_player:
		audio_player.stream = sound
		audio_player.global_transform.origin = position
		audio_player.play()

func get_free_audio_player() -> AudioStreamPlayer3D:
	for player in pool:
		if not player.playing:
			return player
	return null
