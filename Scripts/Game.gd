extends Node2D

const MonsterType := preload("res://Scripts/MonsterType.gd").MonsterType
const GameState := preload("res://Scripts/GameState.gd").GameState
const TileType := preload("res://Scripts/TileType.gd").TileType




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

var first_wait_done:bool
var door_open:bool

var waiting_monsters := 0
var spawn_cooldown := Cooldown.new()
var first_wait_cooldown := Cooldown.new()

var close_door_cooldown := Cooldown.new()


func _ready():
	Globals.setup(
		$Camera2D,
		$EntityContainer,
		$DropContainer,
		$DeadContainer,
		$TransitionLayer/TransitionSprite,
		$TransitionLayer/TransitionSprite/TransitionTween,
		player_scene,
		bullet_scene,
		orb_scene,
		ghost_scene,
		jelly_scene,
		spike_scene,
		tank_scene
	)
	
	Globals.connect("signal_switch_game_state", self,"_on_signal_switch_game_state")
	
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
	
	$MainMenu/MainMenuRoot.visible = false
	$GameOverlay/MarginContainer.visible = false
	$GameOverlay/DeathScreen.visible = false
	$GameOverlay/SuccessScreen.visible = false
	
	if OS.get_name() == "HTML5":
		$MainMenu/MainMenuRoot/MarginContainer/HBoxContainer/VBoxContainer/ExitButton.visible = false
	
	switch_game_state(GameState.MAIN_MENU)

func _process(_delta):
	if state == GameState.LEVEL:
		if door_open:
			if close_door_cooldown.done:
				Mapper.set_tile(Globals.map.door_coord.x, Globals.map.door_coord.y, TileType.WALL)
				door_open = false
				spawn_cooldown.restart()
		else:		
			var open_door:= false
			if !first_wait_done:
				if first_wait_cooldown.done:
					first_wait_done = true
					spawn_cooldown.restart()
					open_door = true
			else:
				if spawn_cooldown.done:
					if waiting_monsters >= 3:
						open_door = true
					else:
						spawn_monster()
						waiting_monsters += 1
						spawn_cooldown.restart()
						
			if open_door:
				Mapper.set_tile(Globals.map.door_coord.x, Globals.map.door_coord.y, TileType.FLOOR)
				close_door_cooldown.restart()
				door_open = true
				waiting_monsters = 0
		



func _input(event):
	if state == GameState.DEATH:
		if event is InputEventMouseButton || event is InputEventKey || event is InputEventJoypadButton:
			Globals.switch_game_state(GameState.MAIN_MENU)


func switch_game_state(new_state) -> void:
	if state == new_state:
		return
		
	var old_state = state
	state = GameState.NONE
	
#	if old_state != GameState.NONE && new_state != GameState.DEATH && old_state != GameState.LEVEL_SUCCESS:
#		Globals.start_transition()
#		yield(Globals, "transition_showing")

	if (old_state == GameState.MAIN_MENU ||
		old_state == GameState.NEXT_LEVEL ||
		old_state == GameState.DEATH):
		Globals.start_transition()
		yield(Globals, "transition_showing")
	
	match old_state:
		GameState.MAIN_MENU:
			main_menu_root.visible = false
			
		GameState.LEVEL:
			game_overlay_root.visible = false

		GameState.NEW_GAME:
			pass

		GameState.NONE:
			pass
			
		GameState.LEVEL_SUCCESS:
			pass		
			
		GameState.NEXT_LEVEL:
			$GameOverlay/SuccessScreen.visible = false
			_stop_level()
			yield(get_tree(), "idle_frame")
			
			get_tree().paused = false

			
		GameState.DEATH:
			$GameOverlay/DeathScreen.visible = false
			
			Engine.time_scale = 1.0
			
			
			_stop_level()
			yield(get_tree(), "idle_frame")
			
			get_tree().paused = false
			
		_:
			assert(false, "Unknown game state %s" % new_state)
	
	state = new_state
	
	match new_state:
		GameState.MAIN_MENU:
			main_menu_root.visible = true

		GameState.NEW_GAME:
			
			Status.start_game()
			switch_game_state(GameState.LEVEL)
			
		GameState.LEVEL:
			start_level()
			
		GameState.LEVEL_SUCCESS:
			get_tree().paused = true
			$GameOverlay/SuccessScreen.visible = true
			
			
		GameState.NEXT_LEVEL:
			switch_game_state(GameState.LEVEL)
			
		GameState.DEATH:
			$GameOverlay/DeathScreen.visible = true
			
			$GameOverlay/DeathScreen/DeathScreen/HBoxContainer/VBoxContainer2/LevelReachedLabel.text = str(Status.level + 1)
			$GameOverlay/DeathScreen/DeathScreen/HBoxContainer/VBoxContainer2/ScoreLabel.text = str(Status.total_coins)
			
			
		_:
			assert(false, "Unknown game state %s" % new_state)
			

func start_level():
	
	Status.start_level()
	
	
	game_overlay_root.visible = true
	
	var map := Map.new(30, 17)
	
	Mapper.generate_map(map)
	Mapper.fill_tilemap(map)
	
	Globals.map = map
	
	yield(get_tree(), "idle_frame")
	
	Globals.create_player(map.player_spawn_coord.to_center_pos())
	
	spawn_cooldown.stop()
	first_wait_cooldown.stop()
	close_door_cooldown.stop()
	
	first_wait_cooldown.setup(self, 4.0, false)
	first_wait_cooldown.restart()
	
	close_door_cooldown.setup(self, 6.0, false)

	
	door_open = false
	first_wait_done = false
	waiting_monsters = 0
	var spawn_interval := 5 - Status.level
	if spawn_interval < 1:
		spawn_interval = 0
	
	spawn_cooldown.setup(self, spawn_interval, false, Cooldown.STOPPED)
	
	for _i in range(3):
		yield(get_tree().create_timer(randf() * 0.4), "timeout")
		spawn_monster()


func spawn_monster():
	var monster_types := []
	
	if Status.level == 0:
		monster_types = [MonsterType.GHOST]
	elif Status.level == 1:
		monster_types = [MonsterType.GHOST, MonsterType.JELLY]
	elif Status.level == 3:
		monster_types = [MonsterType.GHOST, MonsterType.JELLY, MonsterType.SPIKE]
	else:
		 monster_types = [MonsterType.GHOST, MonsterType.JELLY, MonsterType.SPIKE, MonsterType.TANK]
	
	var monster_type = Tools.rand_item(monster_types)
	var spawn_coord:Coord = Tools.rand_item(Globals.map.monster_spawn_coords)
	Globals.create_monster(spawn_coord.to_center_pos(), monster_type)

func _stop_level():
	Globals.destroy_player()
	
	for child in $DropContainer.get_children():
		child.queue_free()

	for child in $DeadContainer.get_children():
		child.queue_free()
		
	for child in $EntityContainer.get_children():
		child.queue_free()


func _on_StartButton_pressed():
	switch_game_state(GameState.NEW_GAME)



func _on_signal_switch_game_state(game_state):
	switch_game_state(game_state)


func _on_ExitButton_pressed():
	get_tree().quit()


func _on_ContinueButton_pressed():
	switch_game_state(GameState.NEXT_LEVEL)
