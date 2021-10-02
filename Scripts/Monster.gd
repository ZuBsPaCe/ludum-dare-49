extends RigidBody2D


onready var _glow_sprite := $Sprites/GlowSprite

func _ready():
	pass

func setup(pos:Vector2):
	position = pos

	yield(self, "ready")

	_glow_sprite.visible = false



func hurt():
	_glow_sprite.visible = true
	
	var tween := Tween.new()
	add_child(tween)

	tween.interpolate_property(
		_glow_sprite,
		"modulate",
		Color(1, 0, 0, 0.5),
		Color(1, 0, 0, 0.0),
		0.5,
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT)
		
	tween.start()

	yield(tween, "tween_completed")
	tween.queue_free()

	_glow_sprite.visible = false
