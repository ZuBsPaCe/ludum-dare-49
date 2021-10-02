extends Node

var _enity_container
var _player_scene: PackedScene
var _bullet_scene: PackedScene
var _monster_scene: PackedScene

var camera: Camera2D
var player: KinematicBody2D

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

func get_global_mouse_position() -> Vector2:
	return _center_node.get_global_mouse_position()
	
