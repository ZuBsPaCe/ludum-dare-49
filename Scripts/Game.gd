extends Node2D

const MonsterType := preload("res://Scripts/MonsterType.gd").MonsterType
const GameState := preload("res://Scripts/GameState.gd").GameState
const TileType := preload("res://Scripts/TileType.gd").TileType

const ItemType := preload("res://Scripts/ItemType.gd").ItemType




export var player_scene:PackedScene
export var bullet_scene:PackedScene
export var orb_scene:PackedScene

export var ghost_scene:PackedScene
export var jelly_scene:PackedScene
export var spike_scene:PackedScene
export var tank_scene:PackedScene


onready var main_menu_root := $MainMenu/MainMenuRoot
onready var game_overlay_root := $GameOverlay/MarginContainer
onready var buy_button1 := $GameOverlay/SuccessScreen/MarginContainer/VBoxContainer/HBoxContainer/BuyLeft/BuyButton1
onready var buy_button2 := $GameOverlay/SuccessScreen/MarginContainer/VBoxContainer/HBoxContainer/BuyLeft/BuyButton2
onready var buy_button3 := $GameOverlay/SuccessScreen/MarginContainer/VBoxContainer/HBoxContainer/BuyLeft/BuyButton3
onready var buy_button4 := $GameOverlay/SuccessScreen/MarginContainer/VBoxContainer/HBoxContainer/BuyLeft/BuyButton4
	
onready var money_button1 := $GameOverlay/SuccessScreen/MarginContainer/VBoxContainer/HBoxContainer/BuyRight/MoneyButton1
onready var money_button2 := $GameOverlay/SuccessScreen/MarginContainer/VBoxContainer/HBoxContainer/BuyRight/MoneyButton2


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
			#game_overlay_root.visible = false
			pass

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
			game_overlay_root.visible = false
			main_menu_root.visible = true

		GameState.NEW_GAME:
			
			Status.start_game()
			switch_game_state(GameState.LEVEL)
			
		GameState.LEVEL:
			start_level()
			
		GameState.LEVEL_SUCCESS:
			get_tree().paused = true
			update_shop()
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
	
	
	

var buy_options := []
var money_options := []

var buy_coins := []
var money_coins := []

func update_shop():
	
	var available_buy := [
		ItemType.AMMO,
		ItemType.HEALTH,
		ItemType.PLAYER_SPEED,
		ItemType.PLAYER_RELOAD,
		ItemType.MACHINEGUN
		]
		
	var available_money := [
		ItemType.SLOW_PLAYER,
		ItemType.FAST_MONSTER,
		ItemType.STRONG_MONSTER
	]
	
	buy_options.clear()
	money_options.clear()
	
	buy_coins.clear()
	money_coins.clear()

	
	while available_buy.size() > 0 && buy_options.size() < 4:
		var rnd := randi() % available_buy.size()
		var option = available_buy[rnd]
		
		available_buy.remove(rnd)
		
		if option in Status.items:
			continue
			
		if option == ItemType.HEALTH && Status.health >= 3:
			continue
		
		buy_options.append(option)
		
		
		
	while available_money.size() > 0 && money_options.size() < 2:
		var rnd := randi() % available_money.size()
		var option = available_money[rnd]
		
		available_money.remove(rnd)
		
		if option in Status.items:
			continue
			
		money_options.append(option)

	var index := -1
	for option in buy_options:
		index += 1
		
		var button:Button
		if index == 0:
			button = buy_button1
		elif index == 1:
			button = buy_button2
		elif index == 2:
			button = buy_button3
		else:
			button = buy_button4
		
		match option:
			ItemType.AMMO:
				buy_coins.append(150)
				button.text = "Ammo"
				
			ItemType.HEALTH:
				buy_coins.append(300)
				button.text = "Health"
				
			ItemType.PLAYER_SPEED:
				buy_coins.append(400)
				button.text = "Speed"
				
			ItemType.PLAYER_RELOAD:
				buy_coins.append(400)
				button.text = "Fast reload"
				
			ItemType.MACHINEGUN:
				buy_coins.append(500)
				button.text = "Machinegun"
				
			_:
				assert(false)
		
		
		button.text += "  " + str(buy_coins.back())
		#print(button.text)
	
	index = -1
	for option in money_options:
		index += 1
		
		var button:Button
		if index == 0:
			button = money_button1
		else:
			button = money_button2
		
		match option:
			ItemType.SLOW_PLAYER:
				money_coins.append(200)
				button.text = "Tired"
				
			ItemType.FAST_MONSTER:
				money_coins.append(250)
				button.text = "Fast monster"
				
			ItemType.STRONG_MONSTER:
				money_coins.append(250)
				button.text = "Strong monster"
				
			
				
			_:
				assert(false)
				
		button.text += "  " + str(money_coins.back())
	
	
	buy_button1.visible = buy_options.size() >= 1
	buy_button2.visible = buy_options.size() >= 2
	buy_button3.visible = buy_options.size() >= 3 
	buy_button4.visible = buy_options.size() >= 4 
	
	money_button1.visible = money_options.size() >= 1
	money_button2.visible = money_options.size() >= 2
	



func _on_BuyButton1_pressed():
	if shopping(buy_options[0], -buy_coins[0]):
		buy_button1.visible = false



func _on_BuyButton2_pressed():
	if shopping(buy_options[1], -buy_coins[1]):
		buy_button2.visible = false


func _on_BuyButton3_pressed():
	if shopping(buy_options[2], -buy_coins[2]):
		buy_button3.visible = false


func _on_BuyButton4_pressed():
	if shopping(buy_options[3], -buy_coins[3]):
		buy_button4.visible = false


func shopping(option, coins) -> bool:
	if !Status.change_coins(coins):
		return false
	
	Status.add_item(option)
	return true
	



func _on_MoneyButton1_pressed():
	shopping(money_options[0], money_coins[0])
	money_button1.visible = false


func _on_MoneyButton2_pressed():
	shopping(money_options[1], money_coins[1])
	money_button2.visible = false


