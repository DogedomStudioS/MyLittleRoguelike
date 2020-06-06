extends TileMap

var claimed_move_targets = []
var tile_contents = {}

func _ready():
  Scheduler.order_completion_handlers.append(self)

func orders_handled(_game_time):
  claimed_move_targets.clear()

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
