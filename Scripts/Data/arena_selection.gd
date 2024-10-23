extends Node3D

@export var selectable_objects: Array[Node3D]
@export var mapIndiactor : Node3D
@export var animPlayer : AnimationPlayer
@export var ballonScene : PackedScene

var selection_tweens : Array[Tween]

var current_index: int = 0

func _ready():
	for obj in selectable_objects:
		var tween = obj.create_tween()
		tween.tween_property(obj,"position:y", 0.5, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(obj,"position:y", 0, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		tween.set_loops(-1)
		selection_tweens.append(tween)
	# 确保选中第一个对象
	update_selection()

func _input(event):
	# 检测左右箭头按键
	if event is InputEventKey and event.pressed:
		if event.is_action_pressed("move_left"):
			current_index = (current_index + selectable_objects.size() - 1) % selectable_objects.size()
			update_selection()
		elif event.is_action_pressed("move_right"):
			current_index = (current_index + selectable_objects.size() + 1) % selectable_objects.size()
			update_selection()
		elif event.is_action_pressed("jump"):
			confirm_selection()

func update_selection():
	# 更新当前选中对象的视觉效果，例如更改颜色或材质
	for i in range(selectable_objects.size()):
		if i == current_index:
			start_floating_animation(selection_tweens[i])
		else:
			stop_floating_animation(selection_tweens[i],selectable_objects[i])
			
func start_floating_animation(tween: Tween):
	tween.stop() # 停止所有其他动画

	tween.play()

func stop_floating_animation(tween: Tween, obj : Node3D):
	tween.stop()
	obj.position.y = 0
	
	
func confirm_selection():
	# 处理确认选定的逻辑
	var selected_object = selectable_objects[current_index]
	print("Selected object:", selected_object.name)
	Global.arena_index = current_index
	# 可以在这里执行特定的操作，例如触发动画或调用函数
	animPlayer.play("fadeOut")
	
func _process(_delta: float) -> void:
	mapIndiactor.global_position = selectable_objects[current_index].global_position

func _on_scene_change() -> void:
	get_tree().change_scene_to_packed(ballonScene)
