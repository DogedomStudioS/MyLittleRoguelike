extends Node2D

var Room = preload("res://level/Room.tscn")
var font = preload("res://assets/RobotoBold120.tres")
onready var Map = $Navigation2D/TileMap
onready var VisibilityMap = $Navigation2D/VisibilityMap
onready var FogMap = $FogOfWar
onready var Player = $Navigation2D/TileMap/Player
onready var Downstairs = $Navigation2D/TileMap/Downstairs
onready var Loading = $"../../UIViewport/Loading"
var Creature = preload("../actors/Creature.tscn")
var GreenApple = preload("../actors/GreenApple.tscn")
var Obstacle = preload("../actors/Obstacle.tscn")

var debug_draw = false
var debug_map_generation = false

var tile_size = 32
var num_rooms = 12
var min_size = 3
var max_size = 8
var h_spread = 100
var cull = 0.15
var door_candidates = []
var tile_rooms = 47
var tile_empty = 52
var tile_threshold = 50
var tile_corridor = 51
var initial_creatures = 9

const GREEN_APPLE_CHANCE = 0.15
const CREATURE_SPAWN_TIME = 45
var last_creature_spawned = 0.0

var path
var start_room = null
var end_room = null


func _ready():
  $Input.frozen_input = true
  Map.fog_of_war = FogMap
  Map.claimed_move_targets = []
  randomize()
  make_rooms()
  setup_message_log()
  Scheduler.order_completion_handlers.append(self)
  if Game.current_floor == 1:
    MessageLog.log("Welcome to Apples Versus Oranges!")


func orders_handled(game_time):
  if game_time - last_creature_spawned > CREATURE_SPAWN_TIME:
    var green_apple_chance = (GREEN_APPLE_CHANCE * float(Game.current_floor)) * 100.0
    print(green_apple_chance)
    var rooms = $Rooms.get_children()
    var random_room = randi() % rooms.size()
    var room = rooms[random_room]
    var s = (room.size / tile_size).floor()
    var ul = (room.position / tile_size).floor() - s
    var tile = Vector2(
      (randi() % int(s.x) * 2 - 1) + int(ul.x), (randi() % int(s.y) * 2 - 1) + int(ul.y)
    )
    if Map.get_cell(tile.x, tile.y) == tile_rooms and not Map.is_location_occupied(tile):
      var new_creature = (
        Creature.instance()
        if randi() % 100 > int(green_apple_chance)
        else GreenApple.instance()
      )
      new_creature.map = Map
      Map.add_child(new_creature)
      new_creature.position = (
        Map.map_to_world(tile).snapped(Vector2.ONE * tile_size)
        + Vector2(tile_size / 2, tile_size / 2)
      )
      Map.add_to_tile(new_creature, Map.world_to_map(new_creature.position))
      last_creature_spawned = game_time


func setup_message_log():
  MessageLog.message_labels = [
    $"../../UIViewport/UI/Messages/message_1",
    $"../../UIViewport/UI/Messages/message_2",
    $"../../UIViewport/UI/Messages/message_3",
  ]


func make_rooms():
  for _i in range(num_rooms):
    var pos = Vector2(rand_range(-h_spread, h_spread), 0)
    var r = Room.instance()
    var w = min_size + randi() % (max_size - min_size)
    var h = min_size + randi() % (max_size - min_size)
    r.make_room(pos, Vector2(w, h) * tile_size)
    $Rooms.add_child(r)
  # wait for rigid bodies to settle
  yield(get_tree().create_timer(1.1), 'timeout')
  var room_positions = []
  # cull rooms
  for room in $Rooms.get_children():
    if randf() < cull:
      room.queue_free()
    else:
      room.mode = RigidBody2D.MODE_STATIC
      room_positions.append(room.position)
  yield(get_tree(), 'idle_frame')
  path = build_room_connections(room_positions)
  if ! debug_map_generation:
    make_map()


func build_room_connections(nodes):
  # connects each point in path with the previous point in the path.
  # Since rooms are randomly distributed, so are cooridors.
  var max_corridor_length = 2000.0
  var unused_nodes = nodes.duplicate(true)
  path = AStar2D.new()
  path.add_point(path.get_available_point_id(), unused_nodes.pop_front())
  var last_point
  var distant_nodes = []

  while unused_nodes:
    last_point = path.get_points().back()
    var node_id = path.get_available_point_id()
    var node = unused_nodes.pop_front()
    path.add_point(node_id, node)
    var new_point = path.get_points().back()
    var distance = node.distance_to(path.get_point_position(last_point))
    if distance < max_corridor_length:
      path.connect_points(last_point, new_point)
    else:
      path.remove_point(node_id)
      distant_nodes.append(node)
  for node in distant_nodes:
    var min_distance = INF
    var p = null
    # Loop through each point in path
    for p1 in path.get_points():
      p1 = path.get_point_position(p1)
      if p1.distance_to(node) < min_distance:
        min_distance = p1.distance_to(node)
        p = p1
    var n = path.get_available_point_id()
    path.add_point(n, node)
    path.connect_points(path.get_closest_point(p), n)
  return path


func make_map():
  # Convert rooms to TileMap
  Map.clear()
  find_start_room()
  find_end_room()
  var full_rect = Rect2()
  for room in $Rooms.get_children():
    var r = Rect2(
      room.position - room.size, room.get_node("CollisionShape2D").shape.extents * 2
    )
    full_rect = full_rect.merge(r)
  full_rect = full_rect.grow(tile_size)
  var topleft = Map.world_to_map(full_rect.position)
  var bottomright = Map.world_to_map(full_rect.end)
  for x in range(topleft.x, bottomright.x):
    for y in range(topleft.y, bottomright.y):
      Map.set_cell(x, y, tile_empty)
      VisibilityMap.set_cell(x, y, 0)

  # Carve rooms
  var corridors = []
  for room in $Rooms.get_children():
    var s = (room.size / tile_size).floor()
    var ul = (room.position / tile_size).floor() - s
    for x in range(1, s.x * 2 - 1):
      for y in range(1, s.y * 2 - 1):
        Map.set_cell(ul.x + x, ul.y + y, tile_rooms)
        VisibilityMap.set_cell(ul.x + x, ul.y + y, -1)
    if initial_creatures > 0:
      initial_creatures -= 1
      var tile = Vector2(
        (randi() % int(s.x) * 2 - 1) + int(ul.x), (randi() % int(s.y) * 2 - 1) + int(ul.y)
      )
      if Map.get_cell(tile.x, tile.y) == tile_rooms and not Map.is_location_occupied(tile):
        var new_creature = Obstacle.instance()#Creature.instance()
        new_creature.map = Map
        Map.add_child(new_creature)
        new_creature.position = (
          Map.map_to_world(tile).snapped(Vector2.ONE * tile_size)
          + Vector2(tile_size / 2, tile_size / 2)
        )
        Map.add_to_tile(new_creature, Map.world_to_map(new_creature.position))
    # Carve connecting corridor
    var p = path.get_closest_point(room.position)
    for conn in path.get_point_connections(p):
      if not conn in corridors:
        var start = Map.world_to_map(
          Vector2(path.get_point_position(p).x, path.get_point_position(p).y)
        )
        var end = Map.world_to_map(
          Vector2(path.get_point_position(conn).x, path.get_point_position(conn).y)
        )
        carve_path(start, end)
    corridors.append(p)
  Map.update_bitmask_region(topleft, bottomright)
  for door in door_candidates:
    pass
    # N, E, S, W
    var neighbors = [
      Map.get_cell(door.x, door.y - 1),
      Map.get_cell(door.x + 1, door.y),
      Map.get_cell(door.x, door.y + 1),
      Map.get_cell(door.x - 1, door.y)
    ]
    Map.set_cell(door.x, door.y, tile_threshold)
    # first check for exactly one floor neighbor
    var floor_neighbors = 0
    var valid_walls = false
    for tile in neighbors:
      if tile == 0:
        floor_neighbors += 1
    if floor_neighbors == 1:
      var north_south_door = neighbors.find(0) % 2 == 0
      if north_south_door:
        valid_walls = neighbors[1] == 1 or neighbors[3] == 1
      else:
        valid_walls = neighbors[0] == 1 or neighbors[2] == 1
      if valid_walls:
        Map.set_cell(door.x, door.y, tile_threshold)
  Player.position = (
    start_room.position.snapped(Vector2.ONE * tile_size)
    + Vector2(tile_size / 2, tile_size / 2)
  )
  Map.add_to_tile(Player, Map.world_to_map(Player.position))
  Downstairs.position = (
    (end_room.position + Vector2(0, 1)).snapped(Vector2.ONE * tile_size)
    + Vector2(tile_size / 2, tile_size / 2)
  )
  Map.add_to_tile(Downstairs, Map.world_to_map(Downstairs.position))
  Map.Downstairs = Downstairs
  $Camera.position = Player.position
  $"../../UIViewport/UI/".current_player = Player
  $"../../UIViewport/UI/".ready = true
  #for room in $Rooms.get_children():
  #room.queue_free()
  Loading.set_visible(false)
  $Input.frozen_input = false


func carve_path(pos1, pos2):
  # Carve a path between two points
  var x_diff = sign(pos2.x - pos1.x)
  var y_diff = sign(pos2.y - pos1.y)
  if x_diff == 0:
    x_diff = pow(-1.0, randi() % 2)
  if y_diff == 0:
    y_diff = pow(-1.0, randi() % 2)
  # choose either x/y or y/x
  var x_y = pos1
  var y_x = pos2
  if (randi() % 2) > 0:
    x_y = pos2
    y_x = pos1
  var last_cell
  for x in range(pos1.x, pos2.x, x_diff):
    var cell = Map.get_cell(x, x_y.y)
    if not last_cell:
      last_cell = cell
    if cell == tile_empty or Map.get_cell_autotile_coord(x, x_y.y) != Vector2(1, 1):
      Map.set_cell(x, x_y.y, tile_rooms)
      VisibilityMap.set_cell(x, x_y.y, -1)
    last_cell = cell
  for y in range(pos1.y, pos2.y, y_diff):
    var cell = Map.get_cell(y_x.x, y)
    if cell == tile_empty or Map.get_cell_autotile_coord(y_x.x, y) != Vector2(1, 1):
      Map.set_cell(y_x.x, y, tile_rooms)
      VisibilityMap.set_cell(y_x.x, y, -1)


func find_start_room():
  var rooms = $Rooms.get_children()
  var room_count = rooms.size()
  start_room = rooms[floor(rand_range(0, room_count - 1))]


func find_end_room():
  var min_distance = 10 * tile_size

  if not start_room:
    print("WARNING: Attempted to find end room before start room was set.")
    return
  var candidate_rooms = []
  for room in $Rooms.get_children():
    var distance = (start_room.position - room.position).length()
    if distance > min_distance:
      candidate_rooms.append(room)
  end_room = candidate_rooms[floor(rand_range(0, candidate_rooms.size() - 1))]


func _draw():
  if debug_draw:
    if start_room:
      draw_string(font, start_room.position - Vector2(125, 0), "start", Color(1, 1, 1))
    if end_room:
      draw_string(font, end_room.position - Vector2(125, 0), "end", Color(1, 1, 1))
    for room in $Rooms.get_children():
      draw_rect(Rect2(room.position - room.size, room.size * 2), Color(32, 228, 0), false)
      if path:
        for p in path.get_points():
          for c in path.get_point_connections(p):
            var pp = path.get_point_position(p)
            var cp = path.get_point_position(c)
            draw_line(
              Vector2(pp.x, pp.y), Vector2(cp.x, cp.y), Color(1, 1, 0), 15, true
            )


func _process(_delta):
  update()
