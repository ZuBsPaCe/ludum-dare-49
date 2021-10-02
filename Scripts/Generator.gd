extends Node


const TileType := preload("res://Scripts/TileType.gd").TileType
const Direction := preload("res://Scripts/Tools/Direction.gd").Direction


func _ready():
	pass
	

func generate_map(map:Map, tilemap:TileMap):
	randomize()
	seed(10)


	for y in map.height:
		for x in map.width:
			if x <= 0 || y <= 0 || x >= map.width - 1 || y >= map.height - 1:
				map.set_item(x, y, TileType.BLOCKED)
			else:
				map.set_item(x, y, TileType.WALL)

	var center_x = map.width / 2
	var center_y = map.height / 2

	for y in range(-1, 2):
		for x in range(-2, 3):
			if x == -2 || x == 2 || y == -1 || y == 1:
				map.set_item(center_x + x, center_y + y, TileType.BLOCKED)
			else:
				map.set_item(center_x + x, center_y + y, TileType.FLOOR)


	var floors := []

	map.set_item(center_x, center_y - 2, TileType.FLOOR)
	floors.append(Coord.new(center_x, center_y - 2))

	var rnd := 10 + randi() % 40
	rnd = 5
	while rnd > 0:
		var coord = Coord.new(
			1 + randi() % (map.width - 2),
			1 + randi() % (map.height - 2))

		if _can_floor(map, coord):
			map.set_item(coord.x, coord.y, TileType.FLOOR)
			floors.append(coord)
			rnd -= 1

	var last_dir_map := Map.new(map.width, map.height)


	for i in 40:
		floors.shuffle()

		var removed_floor_indexes := []
		var new_floors := []

		var index = -1
		for coord in floors:
			index += 1
			
			var last_dir = last_dir_map.get_item(coord.x, coord.y)
			if last_dir != null:
				var next_coord := Tools.step_dir(coord, last_dir)
				
				if _can_floor(map, next_coord):
					map.set_item(next_coord.x, next_coord.y, TileType.FLOOR)
					new_floors.append(next_coord)
					last_dir_map.set_item(next_coord.x, next_coord.y, last_dir)

					continue

			var dir := randi() % 4
			var success := false

			for j in 4:
				dir = (dir + 1) % 4

				var next_coord := Tools.step_dir(coord, dir)
				if _can_floor(map, next_coord):
					
					map.set_item(next_coord.x, next_coord.y, TileType.FLOOR)
					new_floors.append(next_coord)
					last_dir_map.set_item(next_coord.x, next_coord.y, dir)

					success = true
					break

			if !success:
				removed_floor_indexes.push_back(index)

		fill_tilemap(map, tilemap)
		yield(get_tree().create_timer(0.2), "timeout")
		
		#print(floors.size())
		
		for j in range(removed_floor_indexes.size() - 1, -1, -1):
			floors.remove(j)

		floors.append_array(new_floors)



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
				TileType.FLOOR:
					tilemap.set_cell(x, y, 1)

				_:
					pass
					# assert(false)

