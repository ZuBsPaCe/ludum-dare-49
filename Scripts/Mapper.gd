extends Node


const TileType := preload("res://Scripts/TileType.gd").TileType
const Direction := preload("res://Scripts/Tools/Direction.gd").Direction

var _tilemap:TileMap
var _map:Map


func _ready():
	pass
	
func setup(
	p_tilemap:TileMap):
	_tilemap = p_tilemap


func generate_map(map:Map):
	randomize()
	var random_seed = randi()
	#random_seed = 1476648211
	
	seed(random_seed)
	print("Seed: %s" % random_seed)


	for y in map.height:
		for x in map.width:
			if x <= 0 || y <= 0 || x >= map.width - 1 || y >= map.height - 1:
				map.set_item(x, y, TileType.BLOCKED_WALL)
			else:
				map.set_item(x, y, TileType.WALL)
				

	var heads := []
	
	for x in range(1, map.width - 1):
		if x <= 3 || x >= map.width - 4 || randf() < 0.8:
			map.set_item(x, 1, TileType.FLOOR)
			heads.append(Coord.new(x, 1))
	
			map.set_item(x, map.height - 2, TileType.FLOOR)
			heads.append(Coord.new(x, map.height - 2))
			
	for y in range(1, map.height - 1):
		if y <= 3 || y >= map.height - 4 || randf() < 0.8:
			map.set_item(1, y, TileType.FLOOR)
			heads.append(Coord.new(1, y))
	
			map.set_item(map.width - 2, y, TileType.FLOOR)
			heads.append(Coord.new(map.width - 2, y))



	# warning-ignore:integer_division
	var center_x = map.width / 2
	# warning-ignore:integer_division
	var center_y = map.height / 2
	

	for y in range(-1, 2):
		for x in range(-2, 3):
			if x == -2 || x == 2 || y == -1 || y == 1:
				map.set_item(center_x + x, center_y + y, TileType.BLOCKED_WALL)
			else:
				var monster_spawn_coord := Coord.new(center_x + x, center_y + y)
				map.set_item(monster_spawn_coord.x, monster_spawn_coord.y, TileType.BLOCKED_FLOOR)
				map.monster_spawn_coords.append(monster_spawn_coord)

	# Door
	var door_coord := Coord.new(center_x,  center_y - 1)
	#map.set_item(door_coord.x, door_coord.y, TileType.FLOOR)
	map.door_coord = door_coord
	
	
	map.set_item(center_x, center_y - 2, TileType.FLOOR)
	heads.append(Coord.new(center_x, center_y - 2))
	
#	fill_tilemap(map, tilemap)
#	yield(get_tree().create_timer(0.01), "timeout")
	
	while heads.size() > 0:
		var coord:Coord = heads.back()
		
		var floor_neighbours := _count_neighbours(map, coord, TileType.FLOOR)
		
		if floor_neighbours > 2:
			heads.pop_back()
			continue
		
		
		if _can_floor(map, coord):
			map.set_item(coord.x, coord.y, TileType.FLOOR)
			
#			fill_tilemap(map, tilemap)
#			yield(get_tree().create_timer(0.01), "timeout")
		else:
			heads.pop_back()
			
			if map.get_item(coord.x, coord.y) != TileType.FLOOR:
				continue
		
		var dir := randi() % 4
		
		for j in 4:
			dir = (dir + 1) % 4
			
			var next_coord := Tools.step_dir(coord, dir)
			
			if map.get_item(next_coord.x, next_coord.y) == TileType.WALL:
				heads.append(next_coord)
				

#	fill_tilemap(map, tilemap)
#	yield(get_tree().create_timer(0.01), "timeout")
	
	var floors := []
	
	for y in range(1, map.height - 1):
		for x in range(1, map.width - 1):
			if map.get_item(x, y) == TileType.FLOOR:
				floors.append(Coord.new(x, y))
	
	while floors.size() > 0:
		
		var coord:Coord = floors.back()
		
#		if coord.x == 29 && coord.y == 7:
#			pass

		var is_outer := coord.x <= 1 || coord.y <= 1 || coord.x >= map.width - 2 || coord.y >= map.height - 2

		var floor_neighbours := _count_direct_neighbours(map, coord, TileType.FLOOR)
		
		var is_ok := false
		if is_outer:
			is_ok = floor_neighbours >= 3 || floor_neighbours == 2 && randf() < 0.85
		else:
			is_ok = floor_neighbours > 1
				
		if is_ok:
			floors.pop_back()
			continue
			
		var dir := randi() % 4
		
		var success := false

		
		var found_count := 0
		var found_coord :Coord
		
		
		
		for j in 4:
			dir = (dir + 1) % 4
			var next_coord := Tools.step_dir(coord, dir)
			if map.get_item(next_coord.x, next_coord.y) == TileType.WALL: 
				var floor_count := _count_neighbours(map, next_coord, TileType.FLOOR)
				if !success || is_outer && floor_count >= found_count || floor_count <= found_count:
					found_count = floor_count
					found_coord = next_coord
					success = true
		
		if success:
			map.set_item(found_coord.x, found_coord.y, TileType.FLOOR)

			floors.append(found_coord)

#			fill_tilemap(map, tilemap)
#			yield(get_tree().create_timer(0.01), "timeout")
		
		if !success:
#			assert(success, "Ouch...")
			floors.pop_back()
	
	
	for y in map.height:
		for x in map.width:
			match map.get_item(x, y):
				TileType.BLOCKED_WALL:
					
					# No time for proper walk-over-map-border... Sorry...
					#map.set_item(x, y, TileType.WALL)
#					tilemap.set_cell(x, y, 0)
					pass
				TileType.BLOCKED_FLOOR:
					map.set_item(x, y, TileType.FLOOR)
#					tilemap.set_cell(x, y, 1)
	
	var possible_player_x := []
	
	for y in range(map.height - 2, -1, -1):
		possible_player_x.clear()
		
		for x in range(map.width):
			if map.get_item(x, y) == TileType.FLOOR:
				possible_player_x.append(x)
		
		if possible_player_x.size() > 0:
			# warning-ignore:integer_division
			var index = possible_player_x.size() / 2
			map.player_spawn_coord = Coord.new(possible_player_x[index], y)
			break
	
	
	print_debug("Generate Map Done!")



func _count_neighbours(map:Map, coord:Coord, tiletype) -> int:
	var count := 0
	for offset_y in range(-1, 2, 1):
		for offset_x in range(-1, 2, 1):
			if offset_x == 0 && offset_y == 0:
				continue

			if map.get_item(coord.x + offset_x, coord.y + offset_y) == tiletype:
				count += 1

	return count
	
func _count_direct_neighbours(map:Map, coord:Coord, tiletype) -> int:
	var count := 0

	if map.get_item(coord.x, coord.y - 1) == tiletype:
		count += 1
		
	if map.get_item(coord.x + 1, coord.y) == tiletype:
		count += 1
		
	if map.get_item(coord.x, coord.y + 1) == tiletype:
		count += 1
		
	if map.get_item(coord.x - 1, coord.y) == tiletype:
		count += 1

	return count
	
func _can_floor(map:Map, coord:Coord) -> bool:
	if coord.x == 0 || coord.y == 0 || coord.x == map.width - 1 || coord.y == map.height - 1:
		return false
		
	if map.get_item(coord.x, coord.y) != TileType.WALL:
		return false
	
	# Check NE Possible
	if (map.get_item(coord.x, coord.y - 1) != TileType.WALL && 
		map.get_item(coord.x + 1, coord.y - 1) != TileType.WALL &&
		map.get_item(coord.x + 1, coord.y) != TileType.WALL):
		return false;

	# Check SE Possible
	if (map.get_item(coord.x + 1, coord.y) != TileType.WALL && 
		map.get_item(coord.x + 1, coord.y + 1) != TileType.WALL &&
		map.get_item(coord.x, coord.y + 1) != TileType.WALL):
		return false;

	# Check SW Possible
	if (map.get_item(coord.x, coord.y + 1) != TileType.WALL && 
		map.get_item(coord.x - 1, coord.y + 1) != TileType.WALL &&
		map.get_item(coord.x - 1, coord.y) != TileType.WALL):
		return false;

	# Check NW Possible
	if (map.get_item(coord.x - 1, coord.y) != TileType.WALL && 
		map.get_item(coord.x - 1, coord.y - 1) != TileType.WALL &&
		map.get_item(coord.x, coord.y - 1) != TileType.WALL):
		return false;

	return true
			
				
func set_tile(x:int, y:int, tiletype):
	_map.set_item(x, y, tiletype)
	_set_tile_on_tilemap(x, y, tiletype)

			

func _set_tile_on_tilemap(x:int, y:int, tiletype):
	match tiletype:
		TileType.WALL:
			_tilemap.set_cell(x, y, 0)

		TileType.FLOOR:
			_tilemap.set_cell(x, y, 1)
			
		TileType.BLOCKED_WALL:
			_tilemap.set_cell(x, y, 0)
			
		TileType.BLOCKED_FLOOR:
			_tilemap.set_cell(x, y, 1)

		_:
			assert(false)
			pass


func fill_tilemap(map:Map):
	_map = map
	
	var coord := Coord.new()
	
	var orbs := 0
	
	for y in map.height:
		for x in map.width:
			var tiletype = map.get_item(x, y)
			_set_tile_on_tilemap(x, y, tiletype)
			
			var can_orb:= true
			
			if tiletype != TileType.FLOOR:
				can_orb = false
			else:
				for check in map.monster_spawn_coords:
					if check.x == x && check.y == y:
						can_orb = false
						
				if map.player_spawn_coord.x == x && map.player_spawn_coord.y == y:
					can_orb = false
			
			if can_orb:
				coord.x = x
				coord.y = y
				var orb = Globals.create_orb(coord.to_center_pos())
				map.set_orb(x, y, orb)
				orbs += 1
			else:
				map.set_orb(x, y, null)
				
	Status.coins_to_pickup = orbs
