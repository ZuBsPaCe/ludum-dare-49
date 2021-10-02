extends Node

var _full_heart_tex := preload("res://Sprites/Heart/Heart-Full.png")
var _empty_heart_tex := preload("res://Sprites/Heart/Heart-Empty.png")


var level:int
var health:int

var _tex_heart1:TextureRect
var _tex_heart2:TextureRect
var _tex_heart3:TextureRect

var _hurted_cooldown := Cooldown.new()

func _ready():
	_hurted_cooldown.setup(self, 2.5, true, Cooldown.STOPPED)

func setup(
	tex_heart1:TextureRect,
	tex_heart2:TextureRect,
	tex_heart3:TextureRect):
		
	_tex_heart1 = tex_heart1
	_tex_heart2 = tex_heart2
	_tex_heart3 = tex_heart3


func start_game():
	level = -1
	health = 3
	

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
		return


func _update_health_tex():
	_tex_heart1.texture = _full_heart_tex if health >= 1 else _empty_heart_tex
	_tex_heart2.texture = _full_heart_tex if health >= 2 else _empty_heart_tex
	_tex_heart3.texture = _full_heart_tex if health >= 3 else _empty_heart_tex
	
