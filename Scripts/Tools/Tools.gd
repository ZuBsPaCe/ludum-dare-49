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
			
func step_diagonal(coord:Coord, dir1, dir2) -> Coord:
	if dir1 == Direction.N && dir2 == Direction.E || dir1 == Direction.E && dir2 == Direction.N:
		return Coord.new(coord.x + 1, coord.y - 1)
	elif dir1 == Direction.E && dir2 == Direction.S || dir1 == Direction.S && dir2 == Direction.E:
		return Coord.new(coord.x + 1, coord.y + 1)
	elif dir1 == Direction.S && dir2 == Direction.W || dir1 == Direction.W && dir2 == Direction.S:
		return Coord.new(coord.x - 1, coord.y + 1)
	else:
		return Coord.new(coord.x - 1, coord.y - 1)
	

func is_reverse(dir1, dir2) -> bool:
	return (
		dir1 == Direction.N && dir2 == Direction.S ||
		dir1 == Direction.S && dir2 == Direction.N ||
		dir1 == Direction.E && dir2 == Direction.W ||
		dir1 == Direction.W && dir2 == Direction.E)
		
func turn_left(dir) -> int:
	if dir >= 1:
		return dir - 1
	return 3
	
func turn_right(dir) -> int:
	if dir < 3:
		return dir + 1
	return 0
	
func reverse(dir) -> int:
	return (dir + 2) % 4
	
		
func get_vec_from_dir(dir) -> Vector2:
	match dir:
		Direction.N:
			return Vector2.UP
		Direction.E:
			return Vector2.RIGHT
		Direction.S:
			return Vector2.DOWN
		Direction.W:
			return Vector2.LEFT
		_:
			return Vector2.ZERO

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


func raycast_to(from: PhysicsBody2D, to: PhysicsBody2D, collision_mask:int, view_distance: float) -> bool:
#	raycast.clear_exceptions()
#	raycast.add_exception(from)

	_raycast.position = from.position
	_raycast.cast_to = (to.position - from.position).clamped(view_distance)
	_raycast.collision_mask = collision_mask

	_raycast.force_raycast_update()
	
#	debug.append(_raycast.position)
#	debug.append(_raycast.cast_to)
#	z_index = 100
#	update()

	return _raycast.get_collider() == to

#var debug := []
#
#func _draw():
#	for i in range(0, debug.size(), 2):
#		draw_line(debug[i], debug[i] + debug[i + 1], Color.red, 2)
#
#	debug.clear()
