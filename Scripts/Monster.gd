extends KinematicBody2D

export var speed := 64.0

const Direction := preload("res://Scripts/Tools/Direction.gd").Direction
const TileType := preload("res://Scripts/TileType.gd").TileType

onready var _glow_sprite := $Sprites/GlowSprite

var _dir = Direction.N
var _current_coord:= Coord.new()
var _target_pos := Vector2.ZERO
var _update_target_pos := true
var _target_velocity := Vector2.ZERO


func _ready():
	pass

func setup(pos:Vector2):
	position = pos

	yield(self, "ready")

	_glow_sprite.visible = false
	
	_update_target_pos = true
	

func _physics_process(delta):
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
	
	move_and_slide(_target_velocity)

func _try_set_target_pos(current_pos:Coord, dir) -> bool:
	var next_pos := Tools.step_dir(current_pos, dir)
	if Globals.map.get_item(next_pos.x, next_pos.y) == TileType.FLOOR:
		_dir = dir
		_target_pos = next_pos.to_center_pos()
		_target_velocity = Tools.get_vec_from_dir(dir) * speed
		return true
	return false
	

func hurt():
	_glow_sprite.visible = true
	
	var tween := Tween.new()
	add_child(tween)

	tween.interpolate_property(
		_glow_sprite,
		"modulate",
		Color(1, 0, 0, 0.5),
		Color(1, 0, 0, 0.0),
		0.5,
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT)
		
	tween.start()

	yield(tween, "tween_completed")
	tween.queue_free()

	_glow_sprite.visible = false
