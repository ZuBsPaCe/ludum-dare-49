extends Control

onready var title := $Title
onready var title_scale_tween := $Title/TitleScaleTween
onready var title_rotationtween := $Title/TitleRotationTween


func _ready():
	pass


func _process(delta):
	if !title_scale_tween.is_active():
		_start_scale_tween()
		
	if !title_rotationtween.is_active():
		_start_rotation_tween()
		
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
	
	
