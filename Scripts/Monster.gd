extends KinematicBody2D


const Direction := preload("res://Scripts/Tools/Direction.gd").Direction
const TileType := preload("res://Scripts/TileType.gd").TileType
const MonsterType := preload("res://Scripts/MonsterType.gd").MonsterType

onready var sprites:Node2D = $Sprites
onready var glow_sprite:Sprite = $Sprites/Glow
onready var eyes_sprite:Sprite = $Sprites/Eyes
onready var eyes_red_sprite:Sprite = $Sprites/EyesRed
onready var eyes_dead_sprite:Sprite = $Sprites/EyesDead
onready var collision_shape:CollisionShape2D = $Collision
onready var animation_player:AnimationPlayer = $Animation


var monster_type

var _dir = Direction.N
var _current_coord:= Coord.new()
var _target_pos := Vector2.ZERO
var _update_target_pos := true
var _target_velocity := Vector2.ZERO


var _health:int
var _speed:float

var _shoot_cooldown:Cooldown


func _ready():
	pass

func setup(pos:Vector2, p_monsterType, p_health, p_speed):
	position = pos
	monster_type = p_monsterType
	_health = p_health
	_speed = p_speed
	
	match monster_type:
		MonsterType.GHOST:
			pass
		MonsterType.JELLY:
			_shoot_cooldown = Cooldown.new()
			_shoot_cooldown.setup(self, 1.0, true)
	

	yield(self, "ready")
	
	sprites.visible = true
	glow_sprite.visible = false
	eyes_sprite.visible = true
	eyes_red_sprite.visible = false
	eyes_dead_sprite.visible = false
	
	collision_shape.visible = true
	
	animation_player.play("WalkLeft")
	
	_update_target_pos = true

	

func _physics_process(_delta):
	if !_update_target_pos:
		match _dir:
			Direction.N:
				_update_target_pos = position.y <= _target_pos.y
			Direction.E:
				_update_target_pos = position.x >= _target_pos.x
			Direction.S:
				_update_target_pos = position.y >= _target_pos.y
			Direction.W:
				_update_target_pos = position.x <= _target_pos.x
		
	if _update_target_pos:
		_update_target_pos = false
		
		var current_pos := Coord.new()
		current_pos.set_vector(position)
		
		var check_dirs := []
		var straight_first := randf() <= 0.4
		if straight_first:
			check_dirs.append(_dir)
			
		if randf() < 0.5:
			check_dirs.append(Tools.turn_left(_dir))
			check_dirs.append(Tools.turn_right(_dir))
		else:
			check_dirs.append(Tools.turn_right(_dir))
			check_dirs.append(Tools.turn_left(_dir))
			
		if !straight_first:
			check_dirs.append(_dir)
			
		check_dirs.append(Tools.reverse(_dir))
		
		for check_dir in check_dirs:
			if _try_set_target_pos(current_pos, check_dir):
				break
	
	# warning-ignore:return_value_discarded
	move_and_slide(_target_velocity)
	
	if _shoot_cooldown != null && _shoot_cooldown.done:
		_shoot_cooldown.restart()
		if Tools.raycast_to(self, Globals.player, Globals.wall_player_mask, 16.0 * 16.0):
			var dir:Vector2 = (Globals.player.position - self.position).normalized()
			Globals.create_bullet(position + dir * 6.0, dir,  false)

func _try_set_target_pos(current_pos:Coord, dir) -> bool:
	var next_pos := Tools.step_dir(current_pos, dir)
	if Globals.map.get_item(next_pos.x, next_pos.y) == TileType.FLOOR:
		_dir = dir
		_target_pos = next_pos.to_center_pos()
		_target_velocity = Tools.get_vec_from_dir(dir) * _speed
		return true
	return false
	

func hurt():
	if _health <= 0:
		return
		
	_health -= 1
		
	if _health == 0:
		animation_player.stop()
		
		remove_child(collision_shape)
		
		sprites.position = Vector2.ZERO
		
		if randf() < 0.5:
			sprites.global_rotation = deg2rad(-70.0 - randf() * 40.0)
		else:
			sprites.global_rotation = deg2rad(70.0 + randf() * 40.0)
			
		sprites.modulate.a = 0.6
			
		eyes_sprite.visible = false
		eyes_red_sprite.visible = false
		eyes_dead_sprite.visible = true
		
		set_process(false)
		set_physics_process(false)
		#Globals.destroy_monster(self)
	
	
	glow_sprite.visible = true
	
	var tween := Tween.new()
	add_child(tween)

	# warning-ignore:return_value_discarded
	tween.interpolate_property(
		glow_sprite,
		"modulate",
		Color(1, 0, 0, 0.5),
		Color(1, 0, 0, 0.0),
		0.5,
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT)
		
	# warning-ignore:return_value_discarded
	tween.start()

	yield(tween, "tween_completed")
	tween.queue_free()

	glow_sprite.visible = false
