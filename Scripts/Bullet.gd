extends RigidBody2D


var _dir := Vector2.ZERO
var _start := false
var _fade: bool
var _speed: float

var _from_player:bool

func _ready():
	pass

func _physics_process(_delta):
	if _start:
		_start = false
		modulate.a = 1.0
		apply_central_impulse(_dir * _speed)

	elif !_fade:
		var vel := linear_velocity.length()
		if vel <= _speed / 3.0:
			_start_fade()

func setup(p_pos:Vector2, p_dir:Vector2, p_speed:float, from_player:bool, p_layer:int, p_mask:int):
	position = p_pos
	_dir = p_dir
	_speed = p_speed
	
	_from_player = from_player
	
	collision_layer = p_layer
	collision_mask = p_mask

	_start = true
	_fade = false


func _on_Bullet_body_entered(body):
	if _fade:
		return
	
	if body.is_in_group("Monster"):
		body.hurt()
		Globals.destroy_bullet(self)
	elif body.is_in_group("Player"):
		body.hurt()
		Globals.destroy_bullet(self)
	else:
		if body.is_in_group("Tilemap"):
			Globals.hurt_tile(position)
		
		if _from_player:
			linear_damp = 3.0
			_start_fade()
		else:
			Globals.destroy_bullet(self)

func _start_fade():
	_fade = true

	var tween := Tween.new()
	add_child(tween)

	# warning-ignore:return_value_discarded
	tween.interpolate_property(
		self,
		"modulate",
		modulate,
		Tools.get_alpha_0(modulate),
		0.5,
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT)
		
	# warning-ignore:return_value_discarded
	tween.start()

	yield(tween, "tween_completed")
	
	Globals.destroy_bullet(self)
