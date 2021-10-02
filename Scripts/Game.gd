extends Node2D

enum GameState {
	NONE,
	MAIN_MENU,
	NEW_GAME,
	LEVEL
}


export var player_scene:PackedScene
export var bullet_scene:PackedScene
export var monster_scene:PackedScene
export var orb_scene:PackedScene


var state:int = GameState.NONE


func _ready():
	Globals.setup(
		$Camera2D,
		$EntityContainer,
		$DropContainer,
		player_scene,
		bullet_scene,
		monster_scene,
		orb_scene
	)
	
	Mapper.setup(
		$TileMap
	)
	
	Status.setup(
		$GameOverlay/MarginContainer/HBoxContainer/HBoxContainer/TexHeart1,
		$GameOverlay/MarginContainer/HBoxContainer/HBoxContainer/TexHeart2,
		$GameOverlay/MarginContainer/HBoxContainer/HBoxContainer/TexHeart3)
	
	switch_game_state(GameState.NEW_GAME)


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
			pass

		GameState.NEW_GAME:
			start_game()
			
		GameState.LEVEL:
			start_level()

		_:
			assert(false, "Unknown game state %s" % new_state)
			
func start_game():
	Status.start_game()
	
	switch_game_state(GameState.LEVEL)


func start_level():
	Status.start_level()
	
	
	var map := Map.new(30, 17)
	
	Mapper.generate_map(map)
	Mapper.fill_tilemap(map)
	
	Globals.map = map
	
	Globals.create_player(map.player_spawn_coord.to_center_pos())
	
	for _i in range(5):
		var spawn_coord:Coord = Tools.rand_item(map.monster_spawn_coords)
		Globals.create_monster(spawn_coord.to_center_pos())
	
	
