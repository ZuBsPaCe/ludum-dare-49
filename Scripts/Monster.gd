extends KinematicBody2D


const Direction := preload("res://Scripts/Tools/Direction.gd").Direction
const TileType := preload("res://Scripts/TileType.gd").TileType
const MonsterType := preload("res://Scripts/MonsterType.gd").MonsterType
const ItemType := preload("res://Scripts/ItemType.gd").ItemType
const SoundType := preload("res://Scripts/SoundType.gd").SoundType

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

var _shoot_animation:bool
var _is_shooting:bool

var _turn_sprites:bool

var _shoot_cooldown:Cooldown
var _check_cooldown:Cooldown


var _tank_shoot_cooldown:Cooldown
var _tank_fire:bool

func _ready():
	pass

func setup(pos:Vector2, p_monsterType, p_health, p_speed):
	position = pos
	monster_type = p_monsterType
	_health = p_health
	_speed = p_speed
	
	_shoot_cooldown = null
	_shoot_animation = false
	_is_shooting = false
	_turn_sprites = false
	
	match monster_type:
		MonsterType.GHOST:
			pass
		MonsterType.JELLY:
			_shoot_cooldown = Cooldown.new()
			_shoot_cooldown.setup(self, 1.0, true)
		MonsterType.SPIKE:
			_shoot_cooldown = Cooldown.new()
			_shoot_cooldown.setup(self, 6.0, true)
			_shoot_animation = true
		MonsterType.TANK:
			_shoot_cooldown = Cooldown.new()
			_shoot_cooldown.setup(self, 8.0, true)
			
			_tank_shoot_cooldown = Cooldown.new()
			_tank_shoot_cooldown.setup(self, 0.1, true)
			
			_shoot_animation = true
			_turn_sprites = true
	
	
	if ItemType.FAST_MONSTER in Status.items:
		if monster_type != MonsterType.GHOST:
			_speed += 16.0
			
	if ItemType.STRONG_MONSTER in Status.items:
		_health += 5
	
	_check_cooldown = Cooldown.new()
	_check_cooldown.setup(self, 1.0, true)

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

	if _is_shooting:
		if animation_player.is_playing():
			
			if monster_type == MonsterType.TANK:
				_fire_tank()
			
			return
			
			
		_is_shooting = false
		_tank_fire = false

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
	
	if !_turn_sprites:
		if _dir == Direction.W:
			animation_player.play("WalkLeft")
		elif _dir == Direction.E:
			animation_player.play("WalkRight")
	else:
		match _dir:
			Direction.N:
				sprites.rotation_degrees = 90
			Direction.E:
				sprites.rotation_degrees = 180
			Direction.S:
				sprites.rotation_degrees = -90
			_:
				sprites.rotation_degrees = 0
		animation_player.play("WalkLeft")
	
	if _shoot_cooldown != null && _shoot_cooldown.done && _check_cooldown.done:
		_check_cooldown.secs = 0.25 + randf() * 0.25
		_check_cooldown.restart()
		
		var target_found := false
		if monster_type == MonsterType.TANK:
			if Tools.raycast_to(collision_shape.global_position, Globals.player.collision_shape.global_position, Globals.player, Globals.wall_player_mask, 16.0 * 16.0):
				var target_vec:Vector2 = (Globals.player.collision_shape.global_position - collision_shape.global_position).normalized()
				var dir_vec:Vector2 = Tools.get_vec_from_dir(_dir)
				target_found = rad2deg(target_vec.angle_to(dir_vec)) < 25.0
			
		else:
			target_found = Tools.raycast_to(collision_shape.global_position, Globals.player.collision_shape.global_position, Globals.player, Globals.wall_player_mask, 16.0 * 16.0)
			
		if target_found:
			if !_shoot_animation:
				var dir:Vector2 = (Globals.player.position - self.position).normalized()
				Globals.create_bullet(collision_shape.global_position + dir * 6.0, dir,  false)
			else:
				_is_shooting = true
				animation_player.stop()
				animation_player.play("ShootLeft")
				
			_shoot_cooldown.restart()


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
		Globals.play_sound(SoundType.MONSTER_KILL)
		
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
		
	else:
		Globals.play_sound(SoundType.MONSTER_HURT)
	
	
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


func fire_spike():
	for i in 6:
		var angle := randf() * 2.0 * PI
		var dir := Vector2.UP.rotated(angle)
		
		Globals.create_bullet(collision_shape.global_position, dir, false)
		
func fire_tank_start():
	_tank_fire = true
	
func fire_tank_stop():
	_tank_fire = false
	
func _fire_tank():
	if _tank_fire && _tank_shoot_cooldown.done:
		_tank_shoot_cooldown.restart()
	
		var dir_vec:Vector2 = Tools.get_vec_from_dir(_dir)
		
		dir_vec = dir_vec.rotated(deg2rad(randf() * 30.0 - 15.0))
		
		Globals.create_bullet(collision_shape.global_position, dir_vec, false, 256.0)
