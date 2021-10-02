extends Node


const TileType := preload("res://Scripts/TileType.gd").TileType
const Direction := preload("res://Scripts/Tools/Direction.gd").Direction


func _ready():
	pass


func generate_map(map:Map, tilemap:TileMap):
	randomize()
	var random_seed = randi()
	random_seed = 1476648211
	
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



	var center_x = map.width / 2
	var center_y = map.height / 2
	

	for y in range(-1, 2):
		for x in range(-2, 3):
			if x == -2 || x == 2 || y == -1 || y == 1:
				map.set_item(center_x + x, center_y + y, TileType.BLOCKED_WALL)
			else:
				map.set_item(center_x + x, center_y + y, TileType.BLOCKED_FLOOR)


	
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
		
		if coord.x == 29 && coord.y == 7:
			pass

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
					map.set_item(x, y, TileType.WALL)
					tilemap.set_cell(x, y, 0)
				TileType.BLOCKED_FLOOR:
					map.set_item(x, y, TileType.FLOOR)
					tilemap.set_cell(x, y, 1)
	
	
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
			
				

func fill_tilemap(map:Map, tilemap:TileMap):
	for y in map.height:
		for x in map.width:
			var tileType = map.get_item(x, y)

			match tileType:
				TileType.WALL:
					tilemap.set_cell(x, y, 0)
#				TileType.BLOCKED_WALL:
#					tilemap.set_cell(x, y, 0)
				TileType.FLOOR:
					tilemap.set_cell(x, y, 1)
#				TileType.BLOCKED_FLOOR:
#					tilemap.set_cell(x, y, 1)

				_:
					assert(false)
					pass

