extends Node

const TileType := preload("res://Scripts/TileType.gd").TileType
const Direction := preload("res://Scripts/Tools/Direction.gd").Direction

var _enity_container

var _player_scene:PackedScene
var _bullet_scene:PackedScene
var _monster_scene:PackedScene

var camera:Camera2D
var player:KinematicBody2D

var map:Map

var _shake

var _center_node: Node2D;

func _ready():
	_center_node = Node2D.new()
	add_child(_center_node)

func setup(
	p_camera: Camera2D,
	p_entity_container,
	p_player_scene: PackedScene,
	p_bullet_scene: PackedScene,
	p_monster_scene: PackedScene):

	camera = p_camera
	_enity_container = p_entity_container
	_player_scene = p_player_scene
	_monster_scene = p_monster_scene
	_bullet_scene = p_bullet_scene

func create_player(pos: Vector2) -> void:
	assert(player == null)
	player = _player_scene.instance()
	player.setup(pos)
	_enity_container.add_child(player)

func destroy_player() -> void:
	_enity_container.remove_child(player)
	player = null

func create_bullet(pos: Vector2, dir: Vector2) -> void:
	var bullet = _bullet_scene.instance()
	bullet.setup(pos, dir)
	_enity_container.add_child(bullet)

func create_monster(pos: Vector2) -> void:
	var monster = _monster_scene.instance()
	monster.setup(pos)
	_enity_container.add_child(monster)



func shake(dir: Vector2) -> void:
	# camera.start_shake(dir, 1.5, 20, 0.15)
	camera.start_shake(dir, 1.0, 50, 0.3)



func hurt_tile(pos: Vector2) -> void:
	#var coord_vec = body.world_to_map(pos)
	var coord := Coord.new()
	coord.set_vector(pos)
	if map.is_valid(coord.x, coord.y) && map.get_item(coord.x, coord.y) == TileType.WALL:
		Mapper.set_tile(coord.x, coord.y, TileType.FLOOR)
	else:
		var left := false
		var right := false
		var top := false
		var bottom := false
		
		var xmod := fmod(pos.x, 16)
		if xmod < 4:
			left = true
		elif xmod > 12:
			right = true
			
		var ymod := fmod(pos.y, 16)
		if ymod < 4:
			top = true
		elif ymod > 12:
			bottom = true
		
		var check_coords := []
		
		if left && top:
			if xmod < ymod:
				check_coords.append(Tools.step_dir(coord, Direction.W))
				check_coords.append(Tools.step_dir(coord, Direction.N))
			else:
				check_coords.append(Tools.step_dir(coord, Direction.N))
				check_coords.append(Tools.step_dir(coord, Direction.W))
				
			check_coords.append(Tools.step_diagonal(coord, Direction.N, Direction.W))
			
		elif left && bottom:
			if xmod < 16-ymod:
				check_coords.append(Tools.step_dir(coord, Direction.W))
				check_coords.append(Tools.step_dir(coord, Direction.S))
			else:
				check_coords.append(Tools.step_dir(coord, Direction.S))
				check_coords.append(Tools.step_dir(coord, Direction.W))
				
			check_coords.append(Tools.step_diagonal(coord, Direction.S, Direction.W))
	
		elif right && top:
			if 16-xmod < ymod:
				check_coords.append(Tools.step_dir(coord, Direction.E))
				check_coords.append(Tools.step_dir(coord, Direction.N))
			else:
				check_coords.append(Tools.step_dir(coord, Direction.N))
				check_coords.append(Tools.step_dir(coord, Direction.E))
				
			check_coords.append(Tools.step_diagonal(coord, Direction.N, Direction.E))
			
		elif right && bottom:
			if 16-xmod < 16-ymod:
				check_coords.append(Tools.step_dir(coord, Direction.E))
				check_coords.append(Tools.step_dir(coord, Direction.S))
			else:
				check_coords.append(Tools.step_dir(coord, Direction.S))
				check_coords.append(Tools.step_dir(coord, Direction.E))
				
			check_coords.append(Tools.step_diagonal(coord, Direction.S, Direction.E))

		elif left:
			check_coords.append(Tools.step_dir(coord, Direction.W))
		elif right:
			check_coords.append(Tools.step_dir(coord, Direction.E))
		elif top:
			check_coords.append(Tools.step_dir(coord, Direction.N))
		elif bottom:
			check_coords.append(Tools.step_dir(coord, Direction.S))
			
		for check_coord in check_coords:
			if map.is_valid(check_coord.x, check_coord.y) && map.get_item(check_coord.x, check_coord.y) == TileType.WALL:
				Mapper.set_tile(check_coord.x, check_coord.y, TileType.FLOOR)
				break


func get_global_mouse_position() -> Vector2:
	return _center_node.get_global_mouse_position()
	
