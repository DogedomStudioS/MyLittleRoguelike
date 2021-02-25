extends Node

var num_room_tries = 200
var extra_connector_chance = 6
var room_extra_size = 2
var winding_precent = 10
var directions = [Vector2.UP, Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT]

var _rooms = []
var _regions = [[]]
var _current_region = -1
var _map: TileMap
var _bounds = Rect2(0, 0, 81, 41)

func rect_distance_to(a: Rect2, b: Rect2):
    var vertical: int
    var top = min(a.position.y, a.position.y + a.size.y)
    var left = min(a.position.x, a.position.x + a.size.x)
    var bottom = max(a.position.y, a.position.y + a.size.y)
    var right = max(a.position.x, a.position.x + a.size.x)
    var other_top = min(b.position.y, b.position.y + b.size.y)
    var other_left = min(b.position.x, b.position.x + b.size.x)
    var other_bottom = max(b.position.y, b.position.y + b.size.y)
    var other_right = max(b.position.x, b.position.x + b.size.x)

    if top >= other_bottom:
      vertical = top - other_bottom
    elif (bottom <= other_top):
      vertical = other_top - bottom
    else:
      vertical = -1

    var horizontal: int
    if (left >= other_right):
      horizontal = left - other_right
    elif (right <= other_left):
      horizontal = other_left - right
    else:
      horizontal = -1;

    if ((vertical == -1) && (horizontal == -1)): return -1
    if (vertical == -1): return horizontal
    if (horizontal == -1): return vertical
    return horizontal + vertical

func generate_map(map: TileMap):
  for x in _bounds.size.x:
    _regions.resize(_bounds.size.x)
    for y in _bounds.size.y:
      _regions[x] = []
      _regions[x].resize(_bounds.size.y)
      
  _map = map
  for i in _bounds.size.x:
    for j in _bounds.size.y:
      _map.set_cell(i, j, Constants.TILE_TYPES.tile_wall)
  _addRooms()

  for y in range(1, _bounds.size.y, 2):
    for x in range(1, _bounds.size.x, 2):
      var pos = Vector2(x, y)
      if _map.get_cellv(pos) != Constants.TILE_TYPES.tile_wall: continue
      else:
        _grow_maze(pos)
  
  _map.update_dirty_quadrants()
  _connectRegions()
  _map.update_dirty_quadrants()
  _removeDeadEnds()
  _map.update_dirty_quadrants()
  _map.update_bitmask_region()

func _addRooms():
  for _i in range(num_room_tries):
    var size = (randi() % 3 + room_extra_size) * 2 + 1
    var rectangularity = floor(rand_range(0, 1 + (size / 2))) * 2
    var width = size
    var height = size
    if randi() % 2 > 0:
      width += rectangularity
    else:
      height += rectangularity
    var x = floor(rand_range(0, (_bounds.size.x - width) / 2)) * 2 + 1
    var y = floor(rand_range(0, (_bounds.size.y - height) / 2)) * 2 + 1
    var room = Rect2(x, y, width, height)
    var overlaps = false
    for other in _rooms:
      if rect_distance_to(room, other) <= 0:
        overlaps = true
        break
    if overlaps: continue
    _rooms.append(room)
    _startRegion()
    var new_rect = Rect2(x, y, width, height)
    for x1 in new_rect.size.x:
      for y1 in new_rect.size.y:
        _carve(x1 + x, y1 + y, Constants.TILE_TYPES.tile_rooms)

# Implementation of the "growing tree" algorithm from here:
# http://www.astrolog.org/labyrnth/algrithm.htm.
func _grow_maze(start: Vector2):
  var cells = []
  var last_dir
  _startRegion()
  _carve(start.x, start.y)
  cells.append(start)
  while !cells.empty():
    var cell = cells.back()
    var unmade_cells = []
    for direction in directions:
      if _can_carve(cell, direction): unmade_cells.append(direction)
    if !unmade_cells.empty():
      var dir
      if last_dir != null && unmade_cells.find(last_dir) > -1 && randi() % 100 > winding_precent:
        dir = last_dir
      else:
        dir = unmade_cells[randi() % unmade_cells.size()]
      _carve(cell.x + dir.x, cell.y + dir.y, Constants.TILE_TYPES.tile_corridor)
      _carve(cell.x + (dir.x * 2), cell.y + (dir.y * 2), Constants.TILE_TYPES.tile_corridor)
      cells.append(cell + (dir * 2))
      last_dir = dir
    else:
      cells.pop_back()
      last_dir = null

func _connectRegions():
  var connector_regions = {}
  var new_bounds = _bounds.grow(-1)
  for bound_x in range(1, new_bounds.size.x):
    for bound_y in range(1, new_bounds.size.y):
      var pos = Vector2(bound_x, bound_y)
      if _map.get_cellv(pos) != Constants.TILE_TYPES.tile_wall: continue
      var regions = []
      for dir in directions:
        var region_index = pos + dir
        var region = _regions[region_index.x][region_index.y]
        if region != null && regions.find(region) < 0: regions.append(region)
      if regions.size() < 2:
        continue
      else:
        connector_regions["%d,%d" % [bound_x, bound_y]] = regions
  
  var connectors = connector_regions.keys()
  var merged = {}
  var open_regions = []
  for i in range(_current_region + 1):
    merged[i] = i
    if open_regions.find(i) < 0: open_regions.append(i)
  
  while open_regions.size() > 1:
    if connectors.empty():
      return
    var connector = connectors[randi() % connectors.size()]
    var connector_split = connector.split(",")
    var connector_vec = Vector2(float(connector_split[0]), float(connector_split[1]))
    _add_junction(connector_vec)
    # merge connected regions
    var regions = []

    for connector_region in connector_regions[connector]:
      if merged.has(connector_region):
        regions.append(merged[connector_region])
      else:
        print("merged is missing region %d" % [connector_region])
        continue
    var dest = regions[0]
    regions.pop_front()
    var sources = regions

    for i in range(_current_region + 1):
      if sources.find(merged[i]) > -1:
        merged[i] = dest
   
    for source in sources:
      while(open_regions.find(source) > -1):
        open_regions.remove(open_regions.find(source))
    
    var connectors_to_remove = []
    for pos in connectors:
      var split_connector = pos.split(",")
      var used_connector_vec = Vector2(float(split_connector[0]), float(split_connector[1]))

      if connector_vec.distance_to(used_connector_vec) <= 2:
        connectors_to_remove.append(pos)
      else:
        regions = []
        for connector_region in connector_regions[pos]:
          if merged.has(connector_region) && regions.find(merged[connector_region]) < 0:
            regions.append(merged[connector_region])
        
        if regions.size() > 1:
          continue
        if randi() % 100 < extra_connector_chance: _add_junction(used_connector_vec)
        connectors_to_remove.append(pos)
    var new_used_connectors = []
    for used_connector in connectors:
      if connectors_to_remove.find(used_connector) < 0: 
        new_used_connectors.append(used_connector)
    #print("connectors: %d new_used_connectors: %d" % [connectors.size(), new_used_connectors.size()])
    connectors = new_used_connectors


func _add_junction(pos: Vector2):
  # Either an open doorway, closed door, or open door.
  # This will necessitate the door sprites be remade with the intention of 
  # doorwars being part of the corridor vs. part of the room
  _map.set_cellv(pos, Constants.TILE_TYPES.tile_corridor)

func _removeDeadEnds():
  var done = false
  var inflated_bounds = _bounds
  var vectors = []
  for x in range(0, inflated_bounds.size.x):
    for y in range(0, inflated_bounds.size.y):
      vectors.append(Vector2(x, y))
  
  while(!done):
    done = true
    for pos in vectors:
      if _map.get_cellv(pos) == Constants.TILE_TYPES.tile_wall:
        continue
      var exits = 0
      for dir in directions:
        if _map.get_cellv(pos + dir) != Constants.TILE_TYPES.tile_wall:
          exits += 1
      if exits != 1: continue
      
      done = false
      _map.set_cellv(pos, Constants.TILE_TYPES.tile_wall)

func _startRegion():
  _current_region += 1

func _carve(x, y, type = Constants.TILE_TYPES.tile_rooms):
  _map.set_cell(x, y, type)
  _regions[x][y] = _current_region

func _can_carve(pos: Vector2, direction: Vector2):
  return _map.get_cellv(pos + (direction * 3)) == Constants.TILE_TYPES.tile_wall and _map.get_cellv(pos + (direction * 2)) == Constants.TILE_TYPES.tile_wall
