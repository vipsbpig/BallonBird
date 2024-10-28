extends Node3D

@export var selectable_objects: Array[Node3D]
@export var p1Indiactor : Node3D
@export var p2Indiactor : Node3D
@export var animPlayer : AnimationPlayer
@export var gameScene : PackedScene

const animPlayerPath : NodePath = ^"AnimationPlayer"

var selection_tweens : Array[Tween]

var p1_current_index: int = 0
var p2_current_index: int = 0

var p1_is_confirm : bool = false
var p2_is_confirm : bool = false

var sfx_select_1p : AudioStream = preload("res://Audio/audio assets/ui_select_1p.ogg")
var sfx_select_2p : AudioStream = preload("res://Audio/audio assets/ui_select_2p.ogg")

func _ready():
	for obj in selectable_objects:
		var tween = obj.create_tween()
		tween.tween_property(obj,"position:y", 0.5, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(obj,"position:y", 0, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		tween.set_loops(-1)
		(obj.get_node(animPlayerPath) as AnimationPlayer).play("Fly1")
		selection_tweens.append(tween)
	# 确保选中第一个对象
	update_selection()

func _input(event):
	# 检测左右箭头按键
	if (!p1_is_confirm):
		if event is InputEventKey and event.pressed:
			if event.is_action_pressed("move_left"):
				p1_current_index = (p1_current_index + selectable_objects.size() - 1) % selectable_objects.size()
				update_selection()
				Global.play_ui_sfx(sfx_select_1p)
			elif event.is_action_pressed("move_right"):
				p1_current_index = (p1_current_index + selectable_objects.size() + 1) % selectable_objects.size()
				update_selection()
				Global.play_ui_sfx(sfx_select_1p)
			elif event.is_action_pressed("jump"):
				confirm_p1_selection()
			
	# 检测左右箭头按键
	if(!p2_is_confirm):
		if event is InputEventKey and event.pressed:
			if event.is_action_pressed("move_left2"):
				p2_current_index = (p2_current_index + selectable_objects.size() - 1) % selectable_objects.size()
				update_selection()
				Global.play_ui_sfx(sfx_select_2p)
			elif event.is_action_pressed("move_right2"):
				p2_current_index = (p2_current_index + selectable_objects.size() + 1) % selectable_objects.size()
				update_selection()
				Global.play_ui_sfx(sfx_select_2p)
			elif event.is_action_pressed("jump2"):
				confirm_p2_selection()

func update_selection():
	# 更新当前选中对象的视觉效果，例如更改颜色或材质
	for i in range(selectable_objects.size()):
		if (i == p1_current_index && !p1_is_confirm) || (i == p2_current_index && !p2_is_confirm):
			start_floating_animation(selection_tweens[i])
		else:
			stop_floating_animation(selection_tweens[i],selectable_objects[i])
			
func start_floating_animation(tween: Tween):
	tween.stop() # 停止所有其他动画
	tween.play()

func stop_floating_animation(tween: Tween, obj : Node3D):
	tween.stop()
	obj.position.y = 0
	
func confirm_p1_selection():
	# 处理确认选定的逻辑
	var selected_object = selectable_objects[p1_current_index]
	(selected_object.get_node(animPlayerPath) as AnimationPlayer).play("Fly2")
	(selected_object.get_node(animPlayerPath) as AnimationPlayer).queue("Fly1")
	print("Selected p1 object:", selected_object.name)
	Global.p1_ballon_index = p1_current_index
	p1_is_confirm = true
	var sfxpath = "res://Audio/audio assets/ui_confirm_%d.ogg" % (p1_current_index + 1)
	Global.play_ui_sfx(load(sfxpath))
	if p1_current_index != p2_current_index:
		stop_floating_animation(selection_tweens[p1_current_index],selectable_objects[p1_current_index])

func confirm_p2_selection():
	# 处理确认选定的逻辑
	var selected_object = selectable_objects[p2_current_index]
	(selected_object.get_node(animPlayerPath) as AnimationPlayer).play("Fly2")
	(selected_object.get_node(animPlayerPath) as AnimationPlayer).queue("Fly1")
	print("Selected p2 object:", selected_object.name)
	Global.p2_ballon_index = p2_current_index
	p2_is_confirm = true
	var sfxpath = "res://Audio/audio assets/ui_confirm_%d.ogg" % (p2_current_index + 1)
	Global.play_ui_sfx(load(sfxpath))
	if p1_current_index != p2_current_index:
		stop_floating_animation(selection_tweens[p2_current_index],selectable_objects[p2_current_index])

func _process(_delta: float) -> void:
	p1Indiactor.global_position = selectable_objects[p1_current_index].global_position
	p2Indiactor.global_position = selectable_objects[p2_current_index].global_position
	
	if (p1_is_confirm && p2_is_confirm):
		animPlayer.play("fadeOut")

func _on_scene_change() -> void:
	get_tree().change_scene_to_packed(gameScene)
