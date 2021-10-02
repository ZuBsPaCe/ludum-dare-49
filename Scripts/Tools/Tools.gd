extends Node2D

const Direction := preload("res://Scripts/Tools/Direction.gd").Direction

var _raycast : RayCast2D


func _ready():
	_raycast = RayCast2D.new()
	_raycast.enabled = false
	add_child(_raycast)


# Map Helpers

func step_dir(coord:Coord, dir) -> Coord:
	match dir:
		Direction.N:
			return Coord.new(coord.x, coord.y - 1)
		Direction.E:
			return Coord.new(coord.x + 1, coord.y)
		Direction.S:
			return Coord.new(coord.x, coord.y + 1)
		Direction.W:
			return Coord.new(coord.x - 1, coord.y)
		_:
			assert(false)
			return null

# Color Helpers

func get_alpha_1(color: Color) -> Color:
	return Color(color.r, color.g, color.b, 1.0)

func get_alpha_0(color: Color) -> Color:
	return Color(color.r, color.g, color.b, 0.0)

# Array Helpers

func rand_item(array : Array) -> Object:
	return array[randi() % array.size()]

func rand_pop(array : Array) -> Object:
	var index := randi() % array.size()
	var object = array[index]
	array.remove(index)
	return object


# Raycast Helpers

func raycast_dir(from: PhysicsBody2D, dir: Vector2, view_distance: float) -> Object:
	assert(dir.is_equal_approx(dir.normalized()), "Vector is not normalized!")

#	raycast.clear_exceptions()
#	raycast.add_exception(from)

	_raycast.position = from.position
	_raycast.cast_to = from.position + dir * view_distance
	_raycast.collision_mask = from.collision_mask

	_raycast.force_raycast_update()

	return _raycast.get_collider()


func raycast_to(from: PhysicsBody2D, to: PhysicsBody2D, view_distance: float) -> bool:
#	raycast.clear_exceptions()
#	raycast.add_exception(from)

	_raycast.position = from.position
	_raycast.cast_to = (from.position - to.position).clamped(view_distance)
	_raycast.collision_mask = from.collision_mask

	_raycast.force_raycast_update()

	return _raycast.get_collider() == to
