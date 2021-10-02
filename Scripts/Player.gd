extends KinematicBody2D


export var speed := 64.0

onready var _weapon_right := $WeaponRight
onready var _weapon_left := $WeaponLeft
onready var _center := $Center


var _target_velocity := Vector2.ZERO

var _shoot_cooldown := Cooldown.new()

func _ready():
	_shoot_cooldown.setup(self, 0.5, true)
	
	
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

	if Input.is_action_pressed("left_click") && _shoot_cooldown.done:
		_shoot_cooldown.restart()
		
		
		Globals.shake(weapon_dir)
		Globals.create_bullet(weapon.global_position, weapon_dir)


func _physics_process(_delta):
	if _target_velocity != Vector2.ZERO:
#		var old_position := position
	
		# warning-ignore:return_value_discarded
		move_and_slide(_target_velocity)
		
		

func _on_HurtArea2D_body_entered(body):
	if body.is_in_group("Monster"):
		Status.hurt_player()
