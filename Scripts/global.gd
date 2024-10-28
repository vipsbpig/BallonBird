extends Node

var CameraContoller : CameraController

var arena_index = -1
var p1_ballon_index = -1
var p2_ballon_index = -1

var _bgm_player : AudioStreamPlayer
var _ui_sfx_player : AudioStreamPlayer

func _ready():
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.set("parameters/looping", true)
	_ui_sfx_player = AudioStreamPlayer.new()
	add_child(_bgm_player)

func play_bgm(stream : AudioStream):
	if _bgm_player.stream != stream:
		_bgm_player.stream = stream
	if not _bgm_player.playing:
		_bgm_player.play()
		
func stop_bgm():
	_bgm_player.stop()

func play_ui_sfx(stream : AudioStream):
	if _ui_sfx_player.stream != stream:
		_ui_sfx_player.stream = stream
	if not _ui_sfx_player.playing:
		_ui_sfx_player.play()
