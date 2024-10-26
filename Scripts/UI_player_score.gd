extends TextureRect

@onready var container : HBoxContainer = $HBoxContainer

var _score : int = 0
func _ready() -> void:
	SetScore(0)
	
func SetScore(score: int) -> void:
	_score = score
	if (container == null): pass
	for i in container.get_child_count():
		var win = container.get_child(i) as Control
		win.visible = i < _score
