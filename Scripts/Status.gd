extends Node

const _full_heart_tex := preload("res://Sprites/Heart/Heart-Full.png")
const _empty_heart_tex := preload("res://Sprites/Heart/Heart-Empty.png")

const WeaponType := preload("res://Scripts/WeaponType.gd").WeaponType



var level:int
var health:int
var coins:int

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

var max_reload_cooldown_blaster:float
var max_reload_cooldown_machinegun:float

var _tex_heart1:TextureRect
var _tex_heart2:TextureRect
var _tex_heart3:TextureRect
var _coin_label:Label
var _mags_label:Label
var _rounds_rect_front:ColorRect
var _rounds_rect_back:ColorRect

var _hurted_cooldown := Cooldown.new()

var _rounds_rect_front_tween : Tween
var _rounds_rect_back_tween : Tween

func _ready():
	_hurted_cooldown.setup(self, 2.5, true, Cooldown.STOPPED)
	
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
	rounds_rect_front:ColorRect,
	rounds_rect_back:ColorRect):
		
	_tex_heart1 = tex_heart1
	_tex_heart2 = tex_heart2
	_tex_heart3 = tex_heart3
	_coin_label = coin_label
	_mags_label = mags_label
	_rounds_rect_front = rounds_rect_front
	_rounds_rect_back = rounds_rect_back
	


func start_game():
	level = -1
	health = 3
	coins = 0
	current_weapon_index = 0
	
	max_rounds_blaster = 5
	max_rounds_machinegun = 20
	
	max_reload_cooldown_blaster = 3.0
	max_reload_cooldown_machinegun = 4.0
	
	weapons.append(WeaponType.BLASTER)
	weapon_mags.append(0)
	weapon_rounds.append(max_rounds_blaster)
	var fire_cooldown := Cooldown.new()
	fire_cooldown.setup(self, 0.5, true)
	fire_cooldowns.append(fire_cooldown)
	var reload_cooldown := Cooldown.new()
	reload_cooldown.setup(self, max_reload_cooldown_blaster, true)
	reload_cooldowns.append(reload_cooldown)
	
	weapons.append(WeaponType.MACHINEGUN)
	weapon_mags.append(3)
	weapon_rounds.append(max_rounds_machinegun)
	fire_cooldown = Cooldown.new()
	fire_cooldown.setup(self, 0.1, true)
	fire_cooldowns.append(fire_cooldown)
	reload_cooldown = Cooldown.new()
	reload_cooldown.setup(self, max_reload_cooldown_machinegun, true)
	reload_cooldowns.append(reload_cooldown)
	
	_update_health_tex()
	_update_coin_label()
	_update_rounds(false)
	

func start_level():
	level += 1
	
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

func add_coin():
	coins += 1
	_update_coin_label()
	

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
	
func select_prev_weapon():
	current_weapon_index -= 1
	if current_weapon_index < 0:
		current_weapon_index = weapons.size() - 1
	
	_update_rounds(false, true)

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
		_:
			assert(false)
			return 0
