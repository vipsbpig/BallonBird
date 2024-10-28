class_name SFXPool
extends Node

# 初始化音效池
var audio_players = []

# 设置初始化音效播放器数量
const PLAYER_COUNT = 8

func _ready():
	# 自动添加 PLAYER_COUNT 个 AudioStreamPlayer 到池中
	for i in range(PLAYER_COUNT):
		var player = AudioStreamPlayer.new()
		add_child(player)
		audio_players.append(player)

# 播放音效的方法
func play_sfx(sound: AudioStream):
	# 查找第一个空闲的播放器
	for player in audio_players:
		if not player.playing:
			player.stream = sound
			player.play()
			return

	# 如果所有播放器都在使用，重新使用第一个播放器
	audio_players[0].stream = sound
	audio_players[0].stop()  # 确保从头播放
	audio_players[0].play()
