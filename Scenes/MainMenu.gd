extends Control

onready var title := $Title
onready var title_scale_tween := $Title/TitleScaleTween
onready var title_rotationtween := $Title/TitleRotationTween

onready var title_player_tween := $PlayerTitle/TweenPlayer
onready var title_monster1_tween := $TitleMonster1/TweenMonster1
onready var title_monster2_tween := $TitleMonster2/TweenMonster2
onready var title_monster3_tween := $TitleMonster3/TweenMonster3

onready var title_player := $PlayerTitle
onready var title_monster1 := $TitleMonster1
onready var title_monster2 := $TitleMonster2
onready var title_monster3 := $TitleMonster3


var player_pos
var monster1_pos
var monster2_pos
var monster3_pos

func _ready():
	player_pos = title_player.position
	monster1_pos = title_monster1.position
	monster2_pos = title_monster2.position
	monster3_pos = title_monster3.position


func _process(delta):
	if !title_scale_tween.is_active():
		_start_scale_tween()
		
	if !title_rotationtween.is_active():
		_start_rotation_tween()
		
	if !title_player_tween.is_active():
		_start_tween(title_player_tween, title_player, player_pos)
		
	if !title_monster1_tween.is_active():
		_start_tween(title_monster1_tween, title_monster1, monster1_pos)
		
	if !title_monster2_tween.is_active():
		_start_tween(title_monster2_tween, title_monster2, monster2_pos)
		
	if !title_monster3_tween.is_active():
		_start_tween(title_monster3_tween, title_monster3, monster3_pos)
		
func _start_scale_tween():
	var scale_factor = 0.8
	
	var rand_scale := 1.2 + randf() * 0.2
	rand_scale *= scale_factor
	
	title_scale_tween.interpolate_property(
			title,
			"scale",
			title.scale,
			Vector2(rand_scale, rand_scale),
			0.8 + randf() * 0.8,
			Tween.TRANS_SINE, 
			Tween.EASE_IN_OUT)
			
	# warning-ignore:return_value_discarded
	title_scale_tween.start()
	
	yield(title_scale_tween, "tween_completed")
	
	rand_scale = 0.8 + randf() * 0.2
	rand_scale *= scale_factor
	
	title_scale_tween.interpolate_property(
			title,
			"scale",
			title.scale,
			Vector2(rand_scale, rand_scale),
			0.8 + randf() * 0.8,
			Tween.TRANS_SINE, 
			Tween.EASE_IN_OUT)
			
	# warning-ignore:return_value_discarded
	title_scale_tween.start()
	
func _start_rotation_tween():
	var rand_rotation := deg2rad(2.0 + randf() * 2 )
	
	title_rotationtween.interpolate_property(
			title,
			"rotation",
			title.rotation,
			rand_rotation,
			0.8 + randf() * 0.8,
			Tween.TRANS_SINE, 
			Tween.EASE_IN_OUT)
			
	# warning-ignore:return_value_discarded
	title_rotationtween.start()
	
	yield(title_rotationtween, "tween_completed")
	
	rand_rotation = deg2rad(-2.0 - randf() * 2 )
	title_rotationtween.interpolate_property(
			title,
			"rotation",
			title.rotation,
			rand_rotation,
			0.8 + randf() * 0.8,
			Tween.TRANS_SINE, 
			Tween.EASE_IN_OUT)
			
	# warning-ignore:return_value_discarded
	title_scale_tween.start()
	
	
func _start_tween(tween, obj, pos):

	pos.x = pos.x + 10.0 - randf() * 20
	pos.y = pos.y + 10.0 - randf() * 20
	
	tween.interpolate_property(
			obj,
			"position",
			obj.position,
			pos,
			0.3 + randf(),
			Tween.TRANS_SINE, 
			Tween.EASE_IN_OUT)
			
	# warning-ignore:return_value_discarded
	tween.start()
	
	
