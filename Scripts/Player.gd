extends KinematicBody2D


const Direction := preload("res://Scripts/Tools/Direction.gd").Direction
const GameState := preload("res://Scripts/GameState.gd").GameState
const ItemType := preload("res://Scripts/ItemType.gd").ItemType



onready var _weapon_right := $WeaponRight
onready var _weapon_left := $WeaponLeft
onready var _center := $Center

onready var sprites := $Sprites
onready var collision_shape := $CollisionShape2D
onready var glow_sprite := $Sprites/Glow
onready var aura_sprite := $Sprites/Aura
onready var eyes_sprite := $Sprites/Eyes
onready var eyes_dead_sprite := $Sprites/EyesDead


onready var _glow_tween := $GlowTween
onready var _aura_tween := $AuraTween
onready var _black_hole_tween := $BlackHoleTween


onready var _animation_player := $AnimationPlayer
var _animation_dir = Direction.W

var _target_velocity := Vector2.ZERO
var _current_coord := Coord.new()

var speed := 64.0


func _ready():
	aura_sprite.visible = true
	glow_sprite.visible = false
	eyes_sprite.visible = true
	eyes_dead_sprite.visible = false
	
	$BlackHole.visible = false
	
	
func setup(pos:Vector2):
	position = pos
	
	if ItemType.PLAYER_SPEED in Status.items:
		speed *= 1.5
	
	if ItemType.SLOW_PLAYER in Status.items:
		speed *= 0.75


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
	if Status.health == 0:
		return
		
		
	Status.hurt_player()
	
	_start_glow_tween()

	if Status.health == 0:
		
		_start_black_hole_tween()
	
		yield(get_tree().create_timer(0.15), "timeout")
		
		_animation_player.stop()
		
		remove_child(collision_shape)
		
		sprites.position = Vector2.ZERO
		
		if randf() < 0.5:
			sprites.global_rotation = deg2rad(-70.0 - randf() * 40.0)
		else:
			sprites.global_rotation = deg2rad(70.0 + randf() * 40.0)
			
		sprites.modulate.a = 0.6
			
		eyes_sprite.visible = false
		eyes_dead_sprite.visible = true
		
		set_process(false)
		set_physics_process(false)
		#Globals.destroy_monster(self)
		
	
func _start_black_hole_tween():
	$BlackHole.visible = true

	# warning-ignore:return_value_discarded
	_black_hole_tween.interpolate_property(
		$BlackHole,
		"modulate",
		Color(1, 0, 0, 0.0),
		Color(1, 0, 0, 1.0),
		0.3,
		Tween.TRANS_CUBIC, 
		Tween.EASE_OUT)
		
	_black_hole_tween.interpolate_property(
		$BlackHole,
		"scale",
		Vector2(2.0, 2.0),
		Vector2(1.0, 1.0),
		0.3,
		Tween.TRANS_CUBIC, 
		Tween.EASE_OUT)
		
	# warning-ignore:return_value_discarded
	_black_hole_tween.start()

	yield(_black_hole_tween,"tween_completed")

	Globals.switch_game_state(GameState.DEATH)


func _start_glow_tween():
	glow_sprite.visible = true
	aura_sprite.visible = false
	
	_glow_tween.stop(self)
	_aura_tween.stop(self)
	
	# warning-ignore:return_value_discarded
	_glow_tween.interpolate_property(
		glow_sprite,
		"modulate",
		Color(1, 0, 0, 0.5),
		Color(1, 0, 0, 0.0),
		1.0,
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT)
		
	# warning-ignore:return_value_discarded
	_glow_tween.start()
	
	yield(_glow_tween, "tween_completed")
	glow_sprite.visible = false
	
	if Status.health > 0:
		_start_aura_tween()

func _start_aura_tween():
	
	_aura_tween.stop(self)
	
	aura_sprite.modulate = Color(1, 1, 1, 0.0)
	aura_sprite.visible = true
	
	# warning-ignore:return_value_discarded
	_aura_tween.interpolate_property(
		aura_sprite,
		"modulate",
		Color(1, 1, 1, 0.0),
		Color(1, 1, 1, 1.0),
		2.0,
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT)

	# warning-ignore:return_value_discarded
	_aura_tween.start()
