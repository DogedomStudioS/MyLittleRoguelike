extends TileMap

var fog_of_war: TileMap
var claimed_move_targets = []
var tile_contents = {}
var topleft = Vector2(0, 0)
var bottomright = Vector2(0, 0)
var Downstairs
var room_positions = []
var room_sizes = []


func _ready():
  Scheduler.order_completion_handlers.append(self)


func update_visibility():
  for contents in tile_contents:
    for node in tile_contents[contents]:
      if is_instance_valid(node):
        if node.is_in_group(Constants.GROUPS.OBSTACLES):
          var visible = false
          for x in range(-1, 2):
            for y in range(-1, 2):
              if fog_of_war.get_cellv(fog_of_war.world_to_map(node.position + Vector2(x * 32, y * 32))) == -1:
                visible = true
          node.set_visible(visible)
          if (visible):
            fog_of_war.set_cellv(fog_of_war.world_to_map(node.position), -1)
        elif node.is_in_group(Constants.GROUPS.STRUCTURES):
          node.set_visible(true)
        else:
          node.set_visible(fog_of_war.get_cellv(fog_of_war.world_to_map(node.position)) != 0)


func orders_handled(_game_time):
  claimed_move_targets.clear()


func is_location_occupied(location: Vector2):
  var index = _index_for_tile(location)
  if index in tile_contents:
    return tile_contents[index].size() > 0


func is_location_blocked(location: Vector2):
  print("testing location blocked at %d, %d" % [location.x, location.y])
  var collision = get_world_2d().direct_space_state.intersect_point(location, 32, [], Constants.COLLISION_LAYERS.SOLID, true, true)
  print(collision)
  return collision and collision.size() > 0

func is_location_solid_wall(location: Vector2):
  var coords = get_cell_autotile_coord(int(location.x), int(location.y))
  return [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)].find(coords) > -1


func add_to_tile(node: Node2D, destination: Vector2, origin: Vector2 = Vector2(-1, -1)):
  var destination_index = _index_for_tile(destination)
  if origin.x > -1 and origin.y > -1:
    var origin_index = _index_for_tile(origin)
    for object in tile_contents[origin_index]:
      if object != null and is_instance_valid(object) and object.has_method("tile_abandoned"):
        object.tile_abandoned(node)
    var index = tile_contents[origin_index].find(node)
    if index > -1:
      tile_contents[origin_index].remove(index)
  if destination_index in tile_contents:
    for object in tile_contents[destination_index]:
      if object != null and is_instance_valid(object) and object.has_method("tile_occupied"):
        object.tile_occupied(node)
    tile_contents[destination_index].append(node)
  else:
    tile_contents[destination_index] = [node]


func remove_from_tile(node: Node2D, tile: Vector2):
  var tile_index = _index_for_tile(tile)
  if tile_index in tile_contents:
    var index = tile_contents[tile_index].find(node)
    if index > -1:
      tile_contents[tile_index].remove(index)
      var contents = tile_contents[tile_index]
      for object in contents:
        if object != null and is_instance_valid(object) and object.has_method("tile_abandoned"):
          object.tile_abandoned(node)


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

func get_first_surrounding_node_in_group(position: Vector2, group: String):
  var origin = world_to_map(position)
  for x in range(-1, 2):
    for y in range(-1, 2):
      var origin_index = _index_for_tile(origin + Vector2(x, y))
      if origin_index in tile_contents:
        for node in tile_contents[origin_index]:
          if node != null and is_instance_valid(node) and node.is_in_group(group):
            return node
  return null
