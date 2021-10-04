extends Node

const _full_heart_tex := preload("res://Sprites/Heart/Heart-Full.png")
const _empty_heart_tex := preload("res://Sprites/Heart/Heart-Empty.png")

const WeaponType := preload("res://Scripts/WeaponType.gd").WeaponType
const GameState := preload("res://Scripts/GameState.gd").GameState
const ItemType := preload("res://Scripts/ItemType.gd").ItemType

const SoundType := preload("res://Scripts/SoundType.gd").SoundType

var level:int
var health:int
var coins:int

var total_coins:int
var coins_to_pickup:int

var player_bullet_speed := 384.0
var monster_bullet_speed := 64.0

var weapons := []
var weapon_mags := []
var weapon_rounds := []
var fire_cooldowns := []
var reload_cooldowns := []

var current_weapon_index:int

var max_rounds_blaster:int
var max_rounds_machinegun:int
var max_rounds_shotgun:int

var max_reload_cooldown_blaster:float
var max_reload_cooldown_machinegun:float
var max_reload_cooldown_shotgun:float


var items := []



var _tex_heart1:TextureRect
var _tex_heart2:TextureRect
var _tex_heart3:TextureRect
var _coin_label:Label
var _mags_label:Label
var _gun_label:Label
var _rounds_rect_front:ColorRect
var _rounds_rect_back:ColorRect

var _hurted_cooldown := Cooldown.new()

var _rounds_rect_front_tween : Tween
var _rounds_rect_back_tween : Tween

func _ready():
	_hurted_cooldown.setup(self, 1.8, true, Cooldown.STOPPED)
	
	_rounds_rect_front_tween = Tween.new()
	add_child(_rounds_rect_front_tween)
	
	_rounds_rect_back_tween = Tween.new()
	add_child(_rounds_rect_back_tween)

func setup(
	tex_heart1:TextureRect,
	tex_heart2:TextureRect,
	tex_heart3:TextureRect,
	coin_label:Label,
	mags_label:Label,
	gun_label:Label,
	rounds_rect_front:ColorRect,
	rounds_rect_back:ColorRect):
		
	_tex_heart1 = tex_heart1
	_tex_heart2 = tex_heart2
	_tex_heart3 = tex_heart3
	_coin_label = coin_label
	_mags_label = mags_label
	_gun_label = gun_label
	_rounds_rect_front = rounds_rect_front
	_rounds_rect_back = rounds_rect_back
	


func start_game():
	level = -1
	health = 3
	coins = 0
	
	total_coins = 0
	current_weapon_index = 0
	
	items.clear()
	
	max_rounds_blaster = 5
	max_rounds_machinegun = 20
	max_rounds_shotgun = 8
	
	max_reload_cooldown_blaster = 3.0
	max_reload_cooldown_machinegun = 4.0
	max_reload_cooldown_shotgun = 5.0
	
	if !(WeaponType.BLASTER in weapons):
		weapons.append(WeaponType.BLASTER)
		weapon_mags.append(0)
		weapon_rounds.append(max_rounds_blaster)
		var fire_cooldown := Cooldown.new()
		fire_cooldown.setup(self, 0.5, true)
		fire_cooldowns.append(fire_cooldown)
		var reload_cooldown := Cooldown.new()
		reload_cooldown.setup(self, max_reload_cooldown_blaster, true)
		reload_cooldowns.append(reload_cooldown)
	
#	weapons.append(WeaponType.MACHINEGUN)
#	weapon_mags.append(3)
#	weapon_rounds.append(max_rounds_machinegun)
#	fire_cooldown = Cooldown.new()
#	fire_cooldown.setup(self, 0.1, true)
#	fire_cooldowns.append(fire_cooldown)
#	reload_cooldown = Cooldown.new()
#	reload_cooldown.setup(self, max_reload_cooldown_machinegun, true)
#	reload_cooldowns.append(reload_cooldown)
	
	_update_health_tex()
	_update_coin_label()
	_update_rounds(false)
	_show_current_weapon_hint()
	

func start_level():
	level += 1
	_show_current_weapon_hint()
	
func hurt_player():
	if health <= 0:
		return
		
	if !_hurted_cooldown.done:
		return
		
	health -= 1
	_update_health_tex()
	
	_hurted_cooldown.restart()
	
	if health == 0:
		Engine.time_scale = 0.1
		return
	else:
		Globals.play_sound(SoundType.PLAYER_HURT)

func add_coin():
	coins += 1
	total_coins += 1
	coins_to_pickup -= 1
	
	_update_coin_label()
	
	if coins_to_pickup <= 0:# || true: # || coins > level * 10:
		#change_coins(1000)
		Globals.switch_game_state(GameState.LEVEL_SUCCESS)
	else:
		Globals.play_sound(SoundType.COIN_PICKUP)

func change_coins(change:int) -> bool:
	if change < 0 && abs(change) > coins:
		return false
		
	if change > 0:
		Globals.play_sound(SoundType.COIN_PICKUP)
	else:
		Globals.play_sound(SoundType.BUY_SOMETHING)
		
	coins += change
	_update_coin_label()
	return true
	
func add_health():
	health += 1
	_update_health_tex()
	
func add_ammo():
	
	for i in range(weapon_mags.size()):
		weapon_mags[i] += 6
	
	_update_rounds(false, true)
	
	
func add_item(item):

	if item == ItemType.HEALTH:
		Status.add_health()
	elif item == ItemType.AMMO:
		Status.add_ammo()
	else:
		items.append(item)
	
	if item == ItemType.PLAYER_RELOAD:
		for cooldown in reload_cooldowns:
			cooldown.secs *= 0.5
			
	
	if item == ItemType.MACHINEGUN:
		weapons.append(WeaponType.MACHINEGUN)
		weapon_mags.append(6)
		weapon_rounds.append(max_rounds_machinegun)
		var fire_cooldown = Cooldown.new()
		fire_cooldown.setup(self, 0.1, true)
		fire_cooldowns.append(fire_cooldown)
		var reload_cooldown = Cooldown.new()
		reload_cooldown.setup(self, max_reload_cooldown_machinegun, true)
		reload_cooldowns.append(reload_cooldown)
		
		if ItemType.PLAYER_RELOAD in reload_cooldowns:
			reload_cooldown.secs *= 0.5
			
	if item == ItemType.SHOTGUN:
		weapons.append(WeaponType.SHOTGUN)
		weapon_mags.append(6)
		weapon_rounds.append(max_rounds_shotgun)
		var fire_cooldown = Cooldown.new()
		fire_cooldown.setup(self, 1.0, true)
		fire_cooldowns.append(fire_cooldown)
		var reload_cooldown = Cooldown.new()
		reload_cooldown.setup(self, max_reload_cooldown_shotgun, true)
		reload_cooldowns.append(reload_cooldown)
		
		if ItemType.PLAYER_RELOAD in reload_cooldowns:
			reload_cooldown.secs *= 0.5


func try_fire() -> bool:
	var rounds:int = weapon_rounds[current_weapon_index]
	if rounds == 0:
		return false
	
	if !fire_cooldowns[current_weapon_index].done:
		return false
		
	if !reload_cooldowns[current_weapon_index].done:
		return false
	
	rounds -= 1
	weapon_rounds[current_weapon_index] = rounds
	
	fire_cooldowns[current_weapon_index].restart()
	
	var do_reload := false
	
	if rounds <= 0:
		if weapons[current_weapon_index] == WeaponType.BLASTER:
			do_reload = true
		else:
			var mags = weapon_mags[current_weapon_index]
			if mags > 0:
				mags -= 1
				weapon_mags[current_weapon_index] = mags
				do_reload = true
				
		if do_reload:
			reload_cooldowns[current_weapon_index].restart()
			rounds = get_current_max_weapon_rounds()
			weapon_rounds[current_weapon_index] = rounds

	
	_update_rounds(do_reload)
	return true

func select_next_weapon():
	current_weapon_index += 1
	if current_weapon_index >= weapons.size():
		current_weapon_index = 0
	
	_update_rounds(false, true)
	
	_show_current_weapon_hint()
	
func select_prev_weapon():
	current_weapon_index -= 1
	if current_weapon_index < 0:
		current_weapon_index = weapons.size() - 1
	
	_update_rounds(false, true)
	
	_show_current_weapon_hint()
	
func _show_current_weapon_hint():
	var tween := Tween.new()
	add_child(tween)
	
	match weapons[current_weapon_index]:
		WeaponType.BLASTER:
			_gun_label.text = "BLASTER"
		WeaponType.MACHINEGUN:
			_gun_label.text = "MACH.GUN"
		WeaponType.SHOTGUN:
			_gun_label.text = "SHOTGUN"
		_:
			_gun_label.text = "???"
			
	_gun_label.modulate = Color.white
	
	# warning-ignore:return_value_discarded
	tween.interpolate_property(
		_gun_label,
		"modulate",
		Color.white,
		Tools.get_alpha_0(Color.white),
		3.0,
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT)
		
	# warning-ignore:return_value_discarded
	tween.start()
	
	

func _update_health_tex():
	_tex_heart1.texture = _full_heart_tex if health >= 1 else _empty_heart_tex
	_tex_heart2.texture = _full_heart_tex if health >= 2 else _empty_heart_tex
	_tex_heart3.texture = _full_heart_tex if health >= 3 else _empty_heart_tex

func _update_coin_label():
	_coin_label.text = str(coins)

	
func _update_rounds(reload:bool, fast = false):
	_mags_label.text = str(weapon_mags[current_weapon_index])
	
	
	var rounds:int
	
	if !reload:
		rounds = weapon_rounds[current_weapon_index]
	else:
		rounds = 0
	
	var max_rounds := get_current_max_weapon_rounds()
	
	var scale_val := float(rounds) / float(max_rounds)
	var scale := Vector2(scale_val, 1.0)
	
	
	if fast:
		# warning-ignore:return_value_discarded
		_rounds_rect_front_tween.stop(_rounds_rect_front)
		# warning-ignore:return_value_discarded
		_rounds_rect_back_tween.stop(_rounds_rect_back)
		
		_rounds_rect_back.rect_scale = scale
		_rounds_rect_front.rect_scale = scale
		return
		
	
	var fire_cooldown:float = fire_cooldowns[current_weapon_index].secs
	
	# warning-ignore:return_value_discarded
	_rounds_rect_front_tween.stop(_rounds_rect_front)
	
	# warning-ignore:return_value_discarded
	_rounds_rect_front_tween.interpolate_property(
		_rounds_rect_front,
		"rect_scale",
		_rounds_rect_front.rect_scale,
		scale,
		fire_cooldown,
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT)

		
		
	# warning-ignore:return_value_discarded
	_rounds_rect_front_tween.start()
	
	
	_rounds_rect_back.rect_scale = _rounds_rect_front.rect_scale
	
	
	# warning-ignore:return_value_discarded
	_rounds_rect_back_tween.stop(_rounds_rect_back)
	
	# warning-ignore:return_value_discarded
	_rounds_rect_back_tween.interpolate_property(
		_rounds_rect_back,
		"modulate",
		Tools.get_alpha_1(_rounds_rect_back.modulate),
		Tools.get_alpha_0(_rounds_rect_back.modulate),
		0.5,
		Tween.TRANS_CUBIC, 
		Tween.EASE_IN)
		
	# warning-ignore:return_value_discarded
	_rounds_rect_back_tween.start()
	
	if reload:
		var reload_cooldown:float = reload_cooldowns[current_weapon_index].secs
		
		yield(_rounds_rect_front_tween, "tween_completed")
		
		# warning-ignore:return_value_discarded
		_rounds_rect_front_tween.interpolate_property(
			_rounds_rect_front,
			"rect_scale",
			_rounds_rect_front.rect_scale,
			Vector2(1.0, 1.0),
			reload_cooldown - fire_cooldown,
			Tween.TRANS_LINEAR, 
			Tween.EASE_IN_OUT)
			
		# warning-ignore:return_value_discarded
		_rounds_rect_front_tween.start()


func get_current_max_weapon_rounds() -> int:
	match weapons[current_weapon_index]:
		WeaponType.BLASTER:
			return max_rounds_blaster
		WeaponType.MACHINEGUN:
			return max_rounds_machinegun
		WeaponType.SHOTGUN:
			return max_rounds_shotgun
		_:
			assert(false)
			return 0
