extends Control

@onready var container : Control

@export var broken_egg : Texture
@export var good_egg : Texture

var _score : int = 0
var fullscore : int = 2
func _ready() -> void:
	container = self
	SetScore(0)
	
func SetScore(score: int) -> void:
	_score = fullscore - score
	if (container == null): pass
	for i in container.get_child_count():
		var win = container.get_child(i) as TextureRect
		if i < _score : win.texture = good_egg
		else: win.texture = broken_egg
