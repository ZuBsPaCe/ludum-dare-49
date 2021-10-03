extends Node

const TileType := preload("res://Scripts/TileType.gd").TileType
const Direction := preload("res://Scripts/Tools/Direction.gd").Direction
const MonsterType := preload("res://Scripts/MonsterType.gd").MonsterType

const wall_player_mask := (1 << (1-1)) | (1 << (2-1))
const wall_monster_mask := (1 << (1-1)) | (1 << (3-1))

const bullet_player_layer := (1 << (4-1))
const bullet_player_mask := (1 << (1-1)) | (1 << (3-1))

const bullet_monster_layer := (1 << (5-1))
const bullet_monster_mask := (1 << (1-1)) | (1 << (2-1))

var _enity_container
var _drop_container
var _dead_container

var _player_scene:PackedScene
var _bullet_scene:PackedScene
var _orb_scene:PackedScene

var _ghost_scene:PackedScene
var _jelly_scene:PackedScene
var _spike_scene:PackedScene

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
	p_drop_container,
	p_dead_container,
	p_player_scene: PackedScene,
	p_bullet_scene: PackedScene,
	p_orb_scene: PackedScene,
	p_ghost_scene: PackedScene,
	p_jelly_scene: PackedScene,
	p_spike_scene: PackedScene):

	camera = p_camera
	_enity_container = p_entity_container
	_drop_container = p_drop_container
	_dead_container = p_dead_container
	_player_scene = p_player_scene

	_bullet_scene = p_bullet_scene
	_orb_scene = p_orb_scene
	
	_ghost_scene = p_ghost_scene
	_jelly_scene = p_jelly_scene
	_spike_scene = p_spike_scene

func create_player(pos: Vector2) -> void:
	assert(player == null)
	player = _player_scene.instance()
	player.setup(pos)
	_enity_container.add_child(player)

func destroy_player() -> void:
	_enity_container.remove_child(player)
	player.queue_free()
	player = null

func create_bullet(pos: Vector2, dir: Vector2, from_player: bool) -> void:
	var layer:int
	var mask:int
	var speed:int
	
	if from_player:
		layer = bullet_player_layer
		mask = bullet_player_mask
		speed = Status.player_bullet_speed
	else:
		layer = bullet_monster_layer
		mask = bullet_monster_mask
		speed = Status.monster_bullet_speed
	
	var bullet = _bullet_scene.instance()
	bullet.setup(pos, dir, speed, from_player, layer, mask)
	_enity_container.add_child(bullet)
	
func destroy_bullet(bullet):
	_enity_container.remove_child(bullet)
	bullet.queue_free()

func create_monster(pos: Vector2, monster_type) -> void:
	var scene:PackedScene
	
	var health
	var speed
	
	match monster_type:
		MonsterType.GHOST:
			scene = _ghost_scene
			speed = 64.0
			health = 3
		MonsterType.JELLY:
			scene = _jelly_scene
			speed = 32.0
			health = 3
		MonsterType.SPIKE:
			scene = _spike_scene
			speed = 16.0
			health = 5
		_:
			assert(false)
	
	var monster = scene.instance()
	monster.setup(pos, monster_type, health, speed)
	_enity_container.add_child(monster)
	
func monster_died(monster) -> void:
	_enity_container.remove_child(monster)
	_dead_container.add_child(monster)
	
#func destroy_monster(monster) -> void:
#	_enity_container.remove_child(monster)
#	monster.queue_free()

func create_orb(pos: Vector2) -> Node2D:
	var orb = _orb_scene.instance()
	orb.position = pos
	_drop_container.add_child(orb)
	return orb
	
func destroy_orb(orb) -> void:
	_drop_container.remove_child(orb)
	orb.queue_free()


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


func try_pickup_orb(coord: Coord):
	var orb = map.try_get_orb(coord.x, coord.y)
	if orb != null:
		destroy_orb(orb)
		Status.add_coin()
		

func get_global_mouse_position() -> Vector2:
	return _center_node.get_global_mouse_position()
	
