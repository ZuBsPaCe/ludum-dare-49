extends Node2D

const MonsterType := preload("res://Scripts/MonsterType.gd").MonsterType
const GameState := preload("res://Scripts/GameState.gd").GameState
const TileType := preload("res://Scripts/TileType.gd").TileType

const ItemType := preload("res://Scripts/ItemType.gd").ItemType

const SoundType := preload("res://Scripts/SoundType.gd").SoundType


const player_fire1 := preload("res://Sounds/GunFire1.wav")
const player_hurt1 := preload("res://Sounds/Ouch.wav")
const coin_pickup1 := preload("res://Sounds/Coin.wav")
const buy_something1 := preload("res://Sounds/BuySomething.wav")
const monster_kill1 := preload("res://Sounds/MonsterKill.wav")
const monster_kill2 := preload("res://Sounds/MonsterKill2.wav")
const player_dies := preload("res://Sounds/PlayerDies.wav")
const monster_hurt := preload("res://Sounds/MonsterHurt.wav")
const level_start_klick := preload("res://Sounds/LevelStartKlick.wav")
const monster_fire1 := preload("res://Sounds/MonsterFire.wav")
const level_done := preload("res://Sounds/LevelDone.wav")
const mag_empty := preload("res://Sounds/EmptyMag.wav")
const mag_filled := preload("res://Sounds/MagFilled.wav")

const mouse_cursor := preload("res://Art/Cursor.png")

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

onready var sounds := $Sounds

var state:int = GameState.NONE

var first_wait_done:bool
var door_open:bool

var waiting_monsters := 0
var spawn_cooldown := Cooldown.new()
var first_wait_cooldown := Cooldown.new()

var close_door_cooldown := Cooldown.new()

var level_seed:int


func _ready():
	Input.set_custom_mouse_cursor(mouse_cursor, Input.CURSOR_ARROW, Vector2(23.5, 23.5))
	
	Globals.setup(
		$Camera2D,
		$EntityContainer,
		$DropContainer,
		$DeadContainer,
		$TransitionLayer/TransitionSprite,
		$TransitionLayer/TransitionSprite/TransitionTween,
		sounds,
		player_scene,
		bullet_scene,
		orb_scene,
		ghost_scene,
		jelly_scene,
		spike_scene,
		tank_scene
	)
	

	sounds.register(SoundType.PLAYER_FIRE, player_fire1, 70)
	
	sounds.register(SoundType.PLAYER_HURT, player_hurt1, 70)
	sounds.register(SoundType.COIN_PICKUP, coin_pickup1, 70)
	sounds.register(SoundType.BUY_SOMETHING, buy_something1, 70)
	
	sounds.register(SoundType.MONSTER_KILL, monster_kill1, 70)
	sounds.register(SoundType.MONSTER_KILL, monster_kill2, 70)
	
	sounds.register(SoundType.PLAYER_DIES, player_dies, 70)
	sounds.register(SoundType.MONSTER_HURT, monster_hurt, 70)
	sounds.register(SoundType.LEVEL_START_KLICK, level_start_klick, 70)
	
	sounds.register(SoundType.MONSTER_FIRE, monster_fire1, 70)
	
	sounds.register(SoundType.LEVEL_SUCCESS, level_done, 70)
	
	
	sounds.register(SoundType.MAG_EMPTY, mag_empty, 70)
	sounds.register(SoundType.MAG_FILLED, mag_filled, 70)
	
	
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
		$GameOverlay/MarginContainer/GridContainer/HBoxContainer3/RoundsContainer/GunLabel,
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
	if Globals.player != null:
		#sounds.player_pos = Globals.player.global_position
		sounds.global_position = Globals.player.global_position
	
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
			
			
var level_sizes := [
	Coord.new(16, 12),
	Coord.new(17, 13),
	Coord.new(18, 14),
	Coord.new(22, 12),
	Coord.new(16, 16),
	Coord.new(22, 15),
	Coord.new(30, 16),
]

func start_level():
	
	Status.start_level()
	
	
	game_overlay_root.visible = true


#	if Status.level == 0:
#		increase_size = true
#
#	var map:Map
#
#	var width := 16 + Status.level
#	var height := 12 + Status.level
#
#	if width > 30:
#		width = 30
#
#	if height > 16:
#		height = 16

	var size = level_sizes[Status.level % level_sizes.size()]

	var map := Map.new(size.x, size.y)

	randomize()
	level_seed = randi()
	#level_seed = 1476648210
	
	Mapper.generate_map(map, level_seed)
	
	var full_map := Map.new(30, 17)
	for y in full_map.height:
		for x in full_map.width:
			full_map.set_item(x, y, TileType.BLOCKED_WALL)
	
	var offset_x := (full_map.width - map.width) / 2
	var offset_y := (full_map.height - map.height) / 2
	for y in map.height:
		for x in map.width:
			full_map.set_item(x + offset_x, y + offset_y, map.get_item(x, y))
			
#	var door_coord:Coord
#var monster_spawn_coords := []
#var player_spawn_coord:Coord

	full_map.door_coord = Coord.new(map.door_coord.x + offset_x, map.door_coord.y + offset_y)
	full_map.player_spawn_coord = Coord.new(map.player_spawn_coord.x + offset_x, map.player_spawn_coord.y + offset_y)
	
	for coord in map.monster_spawn_coords:
		full_map.monster_spawn_coords.append(Coord.new(coord.x + offset_x, coord.y + offset_y))
	
	map = full_map
	
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
	var spawn_interval = 5.0 - Status.level * 0.5
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
	elif Status.level == 2:
		monster_types = [MonsterType.GHOST, MonsterType.JELLY, MonsterType.TANK]
	elif Status.level == 3:
		monster_types = [MonsterType.GHOST, MonsterType.JELLY, MonsterType.SPIKE]
	else:
		 monster_types = [MonsterType.GHOST, MonsterType.JELLY, MonsterType.TANK, MonsterType.SPIKE]
	
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
	Globals.play_sound(SoundType.LEVEL_START_KLICK)
	
	switch_game_state(GameState.NEW_GAME)



func _on_signal_switch_game_state(game_state):
	switch_game_state(game_state)


func _on_ExitButton_pressed():
	get_tree().quit()


func _on_ContinueButton_pressed():
	Globals.play_sound(SoundType.LEVEL_START_KLICK)
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
		ItemType.MACHINEGUN,
		ItemType.SHOTGUN
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
			
		if option == ItemType.AMMO && Status.weapons.size() <= 1:
			continue
		
		buy_options.append(option)
		
		
		
	while available_money.size() > 0 && money_options.size() < 2:
		var rnd := randi() % available_money.size()
		var option = available_money[rnd]
		
		available_money.remove(rnd)

		if option != ItemType.FAST_MONSTER && option != ItemType.STRONG_MONSTER:
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
				buy_coins.append(200)
				button.text = "Ammo"
				
			ItemType.HEALTH:
				buy_coins.append(250)
				button.text = "Health"
				
			ItemType.PLAYER_SPEED:
				buy_coins.append(250)
				button.text = "Speed"
				
			ItemType.PLAYER_RELOAD:
				buy_coins.append(300)
				button.text = "Fast reload"
				
			ItemType.MACHINEGUN:
				buy_coins.append(300)
				button.text = "Machinegun"
				
			ItemType.SHOTGUN:
				buy_coins.append(350)
				button.text = "Shotgun"
				
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
				money_coins.append(200)
				button.text = "Fast monster"
				
			ItemType.STRONG_MONSTER:
				money_coins.append(200)
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


