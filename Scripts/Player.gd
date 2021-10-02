extends KinematicBody2D


export var speed := 64.0


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


	if Input.is_action_pressed("left_click") && _shoot_cooldown.done:
		_shoot_cooldown.restart()
		
		var dir := (get_global_mouse_position() - position).normalized()
		Globals.shake(dir)
		Globals.create_bullet(position, dir)


func _physics_process(_delta):
	if _target_velocity != Vector2.ZERO:
#		var old_position := position
	
		# warning-ignore:return_value_discarded
		move_and_slide(_target_velocity)
		
		
	
	
