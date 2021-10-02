extends RigidBody2D

export var speed := 128.0


var _dir := Vector2.ZERO
var _start := false
var _fade:bool

func _ready():
	pass

func _physics_process(delta):
	if _start:
		_start = false
		modulate.a = 1.0
		apply_central_impulse(_dir * speed)

	elif !_fade:
		var vel := linear_velocity.length()
		if vel <= 128.0:
			_start_fade()

func setup(p_pos:Vector2, p_dir:Vector2):
	position = p_pos
	_dir = p_dir

	_start = true
	_fade = false


func _on_Bullet_body_entered(body):
	if _fade:
		return
	
	if body.is_in_group("Monster"):
		body.hurt()
		queue_free()
	else:
		linear_damp = 3.0
		_start_fade()

func _start_fade():
	_fade = true

	var tween := Tween.new()
	add_child(tween)

	tween.interpolate_property(
		self,
		"modulate",
		modulate,
		Tools.get_alpha_0(modulate),
		0.5,
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT)
		
	tween.start()

	yield(tween, "tween_completed")
	
	queue_free()
