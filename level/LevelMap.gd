extends TileMap

var fog_of_war: TileMap
var claimed_move_targets = []
var tile_contents = {}
var Downstairs


func _ready():
	Scheduler.order_completion_handlers.append(self)


func update_visibility():
	for contents in tile_contents:
		for node in tile_contents[contents]:
			if is_instance_valid(node):
				node.set_visible(fog_of_war.get_cellv(fog_of_war.world_to_map(node.position)) != 0)


func orders_handled(_game_time):
	claimed_move_targets.clear()


func is_location_occupied(location: Vector2):
	var index = _index_for_tile(location)
	if index in tile_contents:
		return tile_contents[index].size() > 0


func add_to_tile(node: Node2D, destination: Vector2, origin: Vector2 = Vector2(-1, -1)):
	var destination_index = _index_for_tile(destination)
	if origin.x > -1 and origin.y > -1:
		var origin_index = _index_for_tile(origin)
		var index = tile_contents[origin_index].find(node)
		if index > -1:
			tile_contents[origin_index].remove(index)
	if destination_index in tile_contents:
		tile_contents[destination_index].append(node)
	else:
		tile_contents[destination_index] = [node]


func remove_from_tile(node: Node2D, tile: Vector2):
	var tile_index = _index_for_tile(tile)
	if tile_index in tile_contents:
		var index = tile_contents[tile_index].find(node)
		if index > -1:
			tile_contents[tile_index].remove(index)


func get_tile_contents(tile: Vector2):
	var index = _index_for_tile(tile)
	return tile_contents[index] if index in tile_contents else []


func _index_for_tile(tile: Vector2):
	return "%d,%d" % [tile.x, tile.y]


func check_surrounding_tiles_for_node(seek_node, location):
	var origin = world_to_map(location)
	var tile_to_check
	var index = ""
	var found_node = false
	var node_direction = "up"
	for direction in Constants.directions:
		tile_to_check = origin + Constants.directions[direction]
		index = _index_for_tile(tile_to_check)
		if index in tile_contents:
			for node in tile_contents[index]:
				if node == seek_node:
					found_node = true
					node_direction = direction
	return {"found": found_node, "direction": node_direction}


func check_for_node_at_location(seek_node, location):
	var origin = world_to_map(location)
	var origin_index = _index_for_tile(origin)
	if origin_index in tile_contents:
		return tile_contents[origin_index].find(seek_node) > -1
