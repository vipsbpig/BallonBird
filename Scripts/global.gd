extends Node

var CameraContoller : CameraController

var arena_index = -1
var p1_ballon_index = -1
var p2_ballon_index = -1

var _bgm_player : AudioStreamPlayer
var _sfx_pool : SFXPool
var _spatial_audio_pool : SpatialAudioPool

func _ready():
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.set("parameters/looping", true)
	_sfx_pool = SFXPool.new()
	_spatial_audio_pool = SpatialAudioPool.new()
	add_child(_bgm_player)
	add_child(_sfx_pool)
	add_child(_spatial_audio_pool)

func play_bgm(stream : AudioStream):
	if _bgm_player.stream != stream:
		_bgm_player.stream = stream
	if not _bgm_player.playing:
		_bgm_player.play()
		
func stop_bgm():
	_bgm_player.stop()

func play_ui_sfx(stream : AudioStream):
	_sfx_pool.play_sfx(stream)
	
func play_sfx(stream : AudioStream, position : Vector3):
	_spatial_audio_pool.play_sound_at_position(stream, position)
