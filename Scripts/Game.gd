extends Node2D

const MonsterType := preload("res://Scripts/MonsterType.gd").MonsterType


enum GameState {
	NONE,
	MAIN_MENU,
	NEW_GAME,
	LEVEL
}


export var player_scene:PackedScene
export var bullet_scene:PackedScene
export var orb_scene:PackedScene

export var ghost_scene:PackedScene
export var jelly_scene:PackedScene
export var spike_scene:PackedScene
export var tank_scene:PackedScene


onready var main_menu_root := $MainMenu/MainMenuRoot
onready var game_overlay_root := $GameOverlay/MarginContainer


var state:int = GameState.NONE


func _ready():
	Globals.setup(
		$Camera2D,
		$EntityContainer,
		$DropContainer,
		$DeadContainer,
		player_scene,
		bullet_scene,
		orb_scene,
		ghost_scene,
		jelly_scene,
		spike_scene,
		tank_scene
	)
	
	Mapper.setup(
		$TileMap
	)
	
	Status.setup(
		$GameOverlay/MarginContainer/GridContainer/HBoxContainer/TexHeart1,
		$GameOverlay/MarginContainer/GridContainer/HBoxContainer/TexHeart2,
		$GameOverlay/MarginContainer/GridContainer/HBoxContainer/TexHeart3,
		$GameOverlay/MarginContainer/GridContainer/HBoxContainer2/CoinLabel,
		$GameOverlay/MarginContainer/GridContainer/HBoxContainer3/MagsLabel,
		$GameOverlay/MarginContainer/GridContainer/HBoxContainer3/RoundsContainer/RoundsRectFront,
		$GameOverlay/MarginContainer/GridContainer/HBoxContainer3/RoundsContainer/RoundsRectBack)
	
	switch_game_state(GameState.MAIN_MENU)


func switch_game_state(new_state) -> void:
	if state == new_state:
		return
		
	match state:
		GameState.MAIN_MENU:
			pass

		GameState.NEW_GAME:
			pass

		GameState.NONE:
			pass
			
		_:
			assert(false, "Unknown game state %s" % new_state)
	
	state = new_state
	
	match new_state:
		GameState.MAIN_MENU:
			start_main_menu()

		GameState.NEW_GAME:
			start_game()
			
		GameState.LEVEL:
			start_level()

		_:
			assert(false, "Unknown game state %s" % new_state)
			
			
func start_main_menu():
	main_menu_root.visible = true
	game_overlay_root.visible = false
	

func start_game():
	main_menu_root.visible = true	
	
	Status.start_game()
	
	switch_game_state(GameState.LEVEL)


func start_level():
	Status.start_level()
	
	
	game_overlay_root.visible = true
	
	var map := Map.new(30, 17)
	
	Mapper.generate_map(map)
	Mapper.fill_tilemap(map)
	
	Globals.map = map
	
	yield(get_tree(), "idle_frame")
	
	Globals.create_player(map.player_spawn_coord.to_center_pos())
	
	for _i in range(20):
		var monster_types := [MonsterType.GHOST, MonsterType.JELLY, MonsterType.SPIKE, MonsterType.TANK]
		var monster_type = Tools.rand_item(monster_types)
		
		#monster_type = MonsterType.TANK
		
		var spawn_coord:Coord = Tools.rand_item(map.monster_spawn_coords)
		Globals.create_monster(spawn_coord.to_center_pos(), monster_type)
	
	
