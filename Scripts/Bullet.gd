extends RigidBody2D

export var speed := 128.0


var _dir := Vector2.ZERO
var _start := false

func _ready():
	pass

func _physics_process(delta):
	if _start:
		_start = false
		modulate.a = 1.0
		apply_central_impulse(_dir * speed)

	else:
		var vel := linear_velocity.length()
		if vel <= 128.0:
			modulate.a = vel / 128.0
	

func setup(p_pos:Vector2, p_dir:Vector2):
	position = p_pos
	_dir = p_dir

	_start = true


func _on_Bullet_body_entered(body):


	
	# var tween := Tween.new()
	# add_child(tween)

	# tween.interpolate_property(
	# 	self,
	# 	"modulate",
	# 	modulate,
	# 	modulate * Tools.NO_ALPHA,
	# 	0.5,
	# 	Tween.TRANS_LINEAR, 
	# 	Tween.EASE_IN_OUT)
		
	# tween.start()

	# yield(tween, "tween_completed")
	
	# queue_free()
	
	if body.is_in_group("Monster"):
		body.hurt()
		queue_free()
	else:
		linear_damp = 3.0

