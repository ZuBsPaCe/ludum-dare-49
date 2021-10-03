extends KinematicBody2D


const Direction := preload("res://Scripts/Tools/Direction.gd").Direction

export var speed := 64.0

onready var _weapon_right := $WeaponRight
onready var _weapon_left := $WeaponLeft
onready var _center := $Center

onready var collision_shape := $CollisionShape2D
onready var glow_sprite := $Sprites/Glow
onready var auro_sprite := $Sprites/Aura
onready var eyes_sprite := $Sprites/Eyes
onready var eyes_dead_sprite := $Sprites/EyesDead


onready var _animation_player := $AnimationPlayer
var _animation_dir = Direction.W

var _target_velocity := Vector2.ZERO
var _current_coord := Coord.new()



func _ready():
	auro_sprite.visible = true
	glow_sprite.visible = false
	eyes_sprite.visible = true
	eyes_dead_sprite.visible = false
	
	
func setup(pos:Vector2):
	position = pos


func _process(_delta):
	_target_velocity = Vector2.ZERO

	if Input.is_action_pressed("up"):
		_target_velocity.y -= 1

	if Input.is_action_pressed("down"):
		_target_velocity.y += 1

	if Input.is_action_pressed("right"):
		_target_velocity.x += 1

	if Input.is_action_pressed("left"):
		_target_velocity.x -= 1

	_target_velocity = _target_velocity.normalized() * speed
	
	var weapon
	var base_angle:Vector2
	
	var global_mouse_pos = get_global_mouse_position()
	if Vector2.UP.angle_to(global_mouse_pos - _center.global_position) >= 0.0:
		_weapon_left.visible = false
		weapon = _weapon_right
		base_angle = Vector2.RIGHT
	else:
		_weapon_right.visible = false
		weapon = _weapon_left
		base_angle = Vector2.LEFT
		
	weapon.visible = true
	

	var weapon_dir:Vector2 = (get_global_mouse_position() - weapon.global_position).normalized()
	weapon.rotation = base_angle.angle_to(weapon_dir)

	if Input.is_action_pressed("left_click"):
		if Status.try_fire():
			Globals.shake(weapon_dir)
			Globals.create_bullet(weapon.global_position, weapon_dir, true)

func _input(_event):
	if Input.is_action_pressed("next_weapon"):
		Status.select_next_weapon()
	elif Input.is_action_pressed("prev_weapon"):
		Status.select_prev_weapon()



func _physics_process(_delta):
	if _target_velocity != Vector2.ZERO:
#		var old_position := position
	
		# warning-ignore:return_value_discarded
		move_and_slide(_target_velocity)
		
		if _current_coord.set_vector_if_changed(position):
			Globals.try_pickup_orb(_current_coord)
		
		if _target_velocity.x > 0:
			_animation_dir = Direction.E
		elif _target_velocity.y < 0:
			_animation_dir = Direction.W
		
		if _animation_dir == Direction.W:
			_animation_player.play("WalkLeft")
		else:
			_animation_player.play("WalkRight")
		
	else:
		if _animation_dir == Direction.W:
			_animation_player.play("IdleLeft")
		else:
			_animation_player.play("IdleRight")

func _on_HurtArea2D_body_entered(body):
	if body.is_in_group("Monster"):
		hurt()


func hurt():
	Status.hurt_player()
	
	
	glow_sprite.visible = true
	
	var tween := Tween.new()
	add_child(tween)

	# warning-ignore:return_value_discarded
	tween.interpolate_property(
		glow_sprite,
		"modulate",
		Color(1, 0, 0, 0.5),
		Color(1, 0, 0, 0.0),
		1.0,
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT)
		
	# warning-ignore:return_value_discarded
	tween.start()
	
	auro_sprite.visible = false

	yield(tween, "tween_completed")
	tween.queue_free()

	glow_sprite.visible = false
	

	if Status.health > 0:
		
			
		var tween_aura := Tween.new()
		add_child(tween_aura)
		auro_sprite.modulate = Color(1, 1, 1, 0.0)
		auro_sprite.visible = true
		
		# warning-ignore:return_value_discarded
		tween_aura.interpolate_property(
			auro_sprite,
			"modulate",
			Color(1, 1, 1, 0.0),
			Color(1, 1, 1, 1.0),
			2.0,
			Tween.TRANS_LINEAR, 
			Tween.EASE_IN_OUT)
	
		
		# warning-ignore:return_value_discarded
		tween_aura.start()

		yield(tween_aura, "tween_completed")

		tween_aura.queue_free()
