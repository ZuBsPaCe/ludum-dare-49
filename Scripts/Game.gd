extends Node2D

enum GameState {
	NONE,
	MAIN_MENU,
	GAME
}


export var player_scene:PackedScene
export var bullet_scene:PackedScene
export var monster_scene:PackedScene


var state:int = GameState.NONE


func _ready():

	Globals.setup(
		$Camera2D,
		$EntityContainer,
		player_scene,
		bullet_scene,
		monster_scene
	)
	
	switch_game_state(GameState.GAME)


func switch_game_state(new_state) -> void:
	if state == new_state:
		return
		
	match state:
		GameState.MAIN_MENU:
			pass

		GameState.GAME:
			pass

		GameState.NONE:
			pass
			
		_:
			assert(false, "Unknown game state %s" % new_state)
	
	state = new_state
	
	match new_state:
		GameState.MAIN_MENU:
			pass

		GameState.GAME:
			start_game()

		_:
			assert(false, "Unknown game state %s" % new_state)
			

func start_game():
	var map := Map.new(30, 17)
	
	Generator.generate_map(map, $TileMap)
	Generator.fill_tilemap(map, $TileMap)
	
	Globals.create_player(Vector2.ZERO)
	Globals.create_monster(Vector2(3.0, 0.0))
