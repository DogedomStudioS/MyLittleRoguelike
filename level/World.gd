extends Node2D

var Room = preload("res://level/Room.tscn")
var font = preload("res://assets/RobotoBold120.tres")
onready var Map = $Navigation2D/TileMap
onready var VisibilityMap = $Navigation2D/VisibilityMap
onready var FogMap = $FogOfWar
onready var Player = $Navigation2D/TileMap/Player
onready var Downstairs = $Navigation2D/TileMap/Downstairs
onready var Upstairs = $Navigation2D/TileMap/Upstairs
onready var Loading = $"../../UIViewport/Loading"
var Creature = preload("../actors/Creature.tscn")
var GreenApple = preload("../actors/GreenApple.tscn")
var YellowApple = preload("../actors/YellowApple.tscn")
var Obstacle = preload("../actors/Obstacle.tscn")
var PearJuiceBox = preload("../actors/pickups/Juice_Box_Pear.tscn")
var ApplePeeler = preload("../actors/pickups/Apple_Peeler.tscn")
var AppleCorer = preload("../actors/pickups/Apple_Corer.tscn")
var South_Wall_Mid = preload("../actors/South_Wall_Mid.tscn")
var South_Wall_Left = preload("../actors/South_Wall_Left.tscn")
var South_Wall_Right = preload("../actors/South_Wall_Right.tscn")
var Door_N = preload("../actors/Door_N.tscn")
var Door_S = preload("../actors/Door_S.tscn")
var Door_E = preload("../actors/Door_E.tscn")
var Door_W = preload("../actors/Door_W.tscn")

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
var tile_corridor = 54
var initial_creatures = 7
var initial_pickups = 3
var topleft = Vector2(0, 0)
var bottomright = Vector2(0, 0)
var room_positions = []
var room_sizes = []

const GREEN_APPLE_CHANCE = 0.15
const YELLOW_APPLE_CHANCE = 0.1
const CREATURE_SPAWN_TIME = 45
const GREEN_APPLE_LEVEL_CUTOFF = 2
const YELLOW_APPLE_LEVEL_CUTOFF = 4
var last_creature_spawned = 0.0

var path
var start_room = null
var end_room = null

func _ready():
  $Input.frozen_input = true
  if Game.just_launched:
    Game.just_launched = false
    Persistence.load_game()
  Map.fog_of_war = FogMap
  Map.claimed_move_targets = []
  randomize()
  Scheduler.entities = []
  Scheduler.order_completion_handlers.append(self)
  setup_message_log()
  if Game.current_floor == 1:
    MessageLog.log("Welcome to Apples Versus Oranges!")

  if Game.loading_existing_tilemap:
    # Load map tiles here
    var level = Game.existing_level

    for room in level.rooms:
      var r = Room.instance()
      r.make_room(Vector2(int(room.position_x), int(room.position_y)), Vector2(int(room.size_x), int(room.size_y)))
      $Rooms.add_child(r)
      Map.room_positions.append(Vector2(int(room.position_x), int(room.position_y)))
      Map.room_sizes.append(Vector2(int(room.size_x), int(room.size_y)))

    topleft = Vector2(level.topleft_x, level.topleft_y)
    bottomright = Vector2(level.bottomright_x, level.bottomright_y)
    
    for x in range(topleft.x, bottomright.x):
      for y in range(topleft.y, bottomright.y):
        Map.set_cell(x, y, tile_empty)
        VisibilityMap.set_cell(x, y, 0)
        
    Map.topleft = topleft
    Map.bottomright = bottomright
    var cell_data = level.tiles.split(",")
    var max_tile_index = cell_data.size() / 3
    var start_index = 0
    for i in range(0, max_tile_index):
      start_index = i * 3
      Map.set_cell(int(cell_data[start_index]), int(cell_data[start_index + 1]), int(cell_data[start_index + 2]))
      if int(cell_data[start_index + 2]) != tile_empty:
        VisibilityMap.set_cell(int(cell_data[start_index]), int(cell_data[start_index + 1]), -1)
    
    Map.update_dirty_quadrants()
    Map.update_bitmask_region(topleft, bottomright)

    decorate_south_walls()

    Downstairs.position = (
      Map.map_to_world(Vector2(float(level.downstairs_x), float(level.downstairs_y))).snapped(Vector2.ONE * tile_size)
      + Vector2(tile_size / 2, tile_size / 2)
    )
    Map.add_to_tile(Downstairs, Map.world_to_map(Downstairs.position))
    Map.Downstairs = Downstairs

    Upstairs.position = (
      Map.map_to_world(Vector2(float(level.upstairs_x), float(level.upstairs_y))).snapped(Vector2.ONE * tile_size)
      + Vector2(tile_size / 2, tile_size / 2)
    )
    Map.add_to_tile(Upstairs, Map.world_to_map(Upstairs.position))
    Map.Upstairs = Upstairs

    Player.map = Map
    if Game.player_carry_over and "x" in Game.player_carry_over and Game.player_carry_over.x != null:
      Player.position = Map.map_to_world(Vector2(Game.player_carry_over.x, Game.player_carry_over.y)).snapped(Vector2.ONE * tile_size) + Vector2(tile_size / 2, tile_size / 2)
      Game.player_carry_over.x = null
      Game.player_carry_over.y = null
    else:
      var new_player_position = Vector2(level.downstairs_x, level.downstairs_y) if Game.next_level_direction == "up" else Vector2(level.upstairs_x, level.upstairs_y)
      Player.position = Map.map_to_world(new_player_position).snapped(Vector2.ONE * tile_size) + Vector2(tile_size / 2, tile_size / 2)
    Player.load_persistence()
    Map.add_to_tile(Player, Map.world_to_map(Player.position))
    $Camera.position = Player.position
    Game.loading_existing_tilemap = false

    for creature in level.entities.creatures:
      print("loading creature from %s" % [creature.node_name])
      var new_creature = load(creature.node_name).instance()
      new_creature.map = Map
      Map.add_child(new_creature)
      new_creature.position = (
        Map.map_to_world(Vector2(int(creature.x), int(creature.y))).snapped(Vector2.ONE * tile_size)
        + Vector2(tile_size / 2, tile_size / 2)
      )
      Map.add_to_tile(new_creature, Map.world_to_map(new_creature.position))
      new_creature.mortality.hitpoints = int(creature.hitpoints)

    for door in level.entities.doors:
      var new_door = load(door.node_name).instance()
      new_door.closed = door.closed
      new_door.map = Map
      Map.add_child(new_door)
      new_door.position = (
        Map.map_to_world(Vector2(int(door.x), int(door.y))).snapped(Vector2.ONE * tile_size)
        + Vector2(tile_size / 2, tile_size / 2) + Vector2(0, 8)
      )
      Map.add_to_tile(new_door, Map.world_to_map(new_door.position))
    MessageLog.log("Game restored.")


    $"../../UIViewport/UI/".current_player = Player
    $"../../UIViewport/UI/".ready = true
    #for room in $Rooms.get_children():
    #room.queue_free()
    Loading.set_visible(false)
    $Input.frozen_input = false
    Game.loading_existing_tilemap = false
  else:
    make_rooms()


func orders_handled(game_time):
  if game_time - last_creature_spawned > CREATURE_SPAWN_TIME:
    var green_apple_chance = (GREEN_APPLE_CHANCE * float(Game.current_floor)) * 100.0
    var yellow_apple_chance = (YELLOW_APPLE_CHANCE * float(Game.current_floor - YELLOW_APPLE_LEVEL_CUTOFF)) * 100.0
    var rooms = $Rooms.get_children()
    var random_room = randi() % rooms.size()
    var room = rooms[random_room]
    var s = (room.size / tile_size).floor()
    var ul = (room.position / tile_size).floor() - s
    var tile = Vector2(
      (randi() % int(s.x) * 2 - 1) + int(ul.x), (randi() % int(s.y) * 2 - 1) + int(ul.y) + 1
    )
    if Map.get_cell(tile.x, tile.y) == tile_rooms and not Map.is_location_occupied(tile) and not Map.is_location_solid_wall(tile):
      var spawn_green_apple = randi() % 100 < int(green_apple_chance) and Game.current_floor >= GREEN_APPLE_LEVEL_CUTOFF
      var spawn_yellow_apple = randi() % 100 < int(yellow_apple_chance) and Game.current_floor >= YELLOW_APPLE_LEVEL_CUTOFF
      var new_creature
      if spawn_yellow_apple:
        print("spawned yellow apple.")
        new_creature = YellowApple.instance()
      elif spawn_green_apple:
        new_creature = GreenApple.instance()
      else:
        new_creature = Creature.instance()
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
  # cull rooms
  for room in $Rooms.get_children():
    if randf() < cull:
      room.queue_free()
    else:
      room.mode = RigidBody2D.MODE_STATIC
      room_positions.append(room.position)
      room_sizes.append(room.size)
  yield(get_tree(), 'idle_frame')
  path = build_room_connections(room_positions)
  Map.room_positions = room_positions
  Map.room_sizes = room_sizes
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

func decorate_south_walls():
  for x in range(topleft.x, bottomright.x):
    for y in range(topleft.y, bottomright.y):
      var autotile = Map.get_cell_autotile_coord(x, y)
      if autotile == Vector2(0, 2) or autotile == Vector2(1, 2) or autotile == Vector2(2, 2):
        var new_south_wall
        if autotile == Vector2(0, 2):
          new_south_wall = South_Wall_Left.instance()
        elif autotile == Vector2(2, 2):
          new_south_wall = South_Wall_Right.instance()
        else:
          new_south_wall = South_Wall_Mid.instance()
        new_south_wall.map = Map
        Map.add_child(new_south_wall)
        new_south_wall.position = (
          Map.map_to_world(Vector2(x, y)).snapped(Vector2.ONE * tile_size)
          + Vector2(tile_size / 2, tile_size / 2)
        )
        Map.add_to_tile(new_south_wall, Map.world_to_map(new_south_wall.position))

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
  topleft = Map.world_to_map(full_rect.position)
  Map.topleft = topleft
  bottomright = Map.world_to_map(full_rect.end)
  Map.bottomright = bottomright
  for x in range(topleft.x, bottomright.x):
    for y in range(topleft.y, bottomright.y):
      Map.set_cell(x, y, tile_empty)
      VisibilityMap.set_cell(x, y, 0)

  Map.update_dirty_quadrants()
  Map.update_bitmask_region(topleft, bottomright)

  # Carve rooms
  var corridors = []
  var paths = []
  for room in $Rooms.get_children():
    var s = (room.size / tile_size).floor()
    var ul = (room.position / tile_size).floor() - s
    for x in range(1, s.x * 2 - 1):
      for y in range(1, s.y * 2 - 1):
        Map.set_cell(ul.x + x, ul.y + y, tile_rooms)
        VisibilityMap.set_cell(ul.x + x, ul.y + y, -1)
    Map.update_bitmask_region(ul, ul + s)
    if room != start_room and initial_creatures > 0:
      var tile = Vector2(
        (randi() % int(s.x) * 2 - 1) + int(ul.x), (randi() % int(s.y) * 2 - 1) + int(ul.y) + 1
      )
      if Map.get_cell(tile.x, tile.y) == tile_rooms and not Map.is_location_occupied(tile) and not Map.is_location_solid_wall(tile):
        var new_creature = Creature.instance()
        new_creature.map = Map
        Map.add_child(new_creature)
        new_creature.position = (
          Map.map_to_world(tile).snapped(Vector2.ONE * tile_size)
          + Vector2(tile_size / 2, tile_size / 2)
        )
        Map.add_to_tile(new_creature, Map.world_to_map(new_creature.position))
        initial_creatures -= 1
    if room != start_room and initial_pickups > 0:
      var tile = Vector2(
        (randi() % int(s.x) * 2 - 1) + int(ul.x), (randi() % int(s.y) * 2 - 1) + int(ul.y) + 1
      )
      if Map.get_cell(tile.x, tile.y) == tile_rooms and not Map.is_location_solid_wall(tile):
        var new_pickup
        if Game.current_floor > GREEN_APPLE_LEVEL_CUTOFF and Game.current_floor <= YELLOW_APPLE_LEVEL_CUTOFF and initial_pickups == 1:
          print("spawned peeler.")
          new_pickup = ApplePeeler.instance()
        elif Game.current_floor > YELLOW_APPLE_LEVEL_CUTOFF and initial_pickups == 1:
          print("spawned corer.")
          new_pickup = AppleCorer.instance()
        else:
          new_pickup = PearJuiceBox.instance()
        new_pickup.map = Map
        Map.add_child(new_pickup)
        new_pickup.position = (
          Map.map_to_world(tile).snapped(Vector2.ONE * tile_size)
          + Vector2(tile_size / 2, tile_size / 2)
        )
        Map.add_to_tile(new_pickup, Map.world_to_map(new_pickup.position))
        initial_pickups -= 1
    # Carve connecting corridor
    var p = path.get_closest_point(room.position)
    paths.append(p)
  
  Map.update_dirty_quadrants()
  Map.update_bitmask_region(topleft, bottomright)

  for p in paths:
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
  
  Map.update_dirty_quadrants()
  Map.update_bitmask_region(topleft, bottomright)
  decorate_south_walls()
  for door in door_candidates:
    if randi() % 100 > 50:
      pass
    # N, E, S, W
    var neighbors = [
      Map.get_cell(door.x, door.y - 1),
      Map.get_cell(door.x + 1, door.y),
      Map.get_cell(door.x, door.y + 1),
      Map.get_cell(door.x - 1, door.y)
    ]
    var corridor_neighbors = 0
    var neighbor_index = 0
    var new_door = null
    for i in range (0, neighbors.size()):
      if neighbors[i] == tile_corridor:
        corridor_neighbors += 1
        neighbor_index = i
    if corridor_neighbors == 1:
      if neighbor_index == 0:
        new_door = Door_N.instance()
      elif neighbor_index == 1:
        new_door = Door_E.instance()
      elif neighbor_index == 2:
        new_door = Door_S.instance()
      elif neighbor_index == 3:
        new_door = Door_W.instance()
    if new_door and not Map.is_location_occupied(door):
      new_door.map = Map
      Map.add_child(new_door)
      new_door.position = (
        Map.map_to_world(door).snapped(Vector2.ONE * tile_size)
        + Vector2(tile_size / 2, tile_size / 2) + Vector2(0, 8)
      )
      Map.add_to_tile(new_door, Map.world_to_map(new_door.position))
  
  Player.map = Map
  var start_position = start_room.position.snapped(Vector2.ONE * tile_size) + Vector2(tile_size / 2, tile_size / 2) 
  var try_position = start_position
  var positionValid = false
  var tries = 0
  while not positionValid: 
    if not Map.is_location_occupied(Map.world_to_map(try_position)) and not Map.is_location_solid_wall(Map.world_to_map(try_position)):
      positionValid = true
      break
    if tries < 16:
      if tries % 2 == 0:
        try_position.x += tile_size
      else:
        try_position.y += tile_size
    elif tries >= 16 and tries < 32:
      if tries == 16:
        try_position = start_position
      if tries % 2 == 0:
        try_position.x -= tile_size
      else:
        try_position.y += tile_size
    elif tries >= 32 and tries < 48:
      if tries == 32:
        try_position = start_position
      if tries % 2 == 0:
        try_position.x += tile_size
      else:
        try_position.y -= tile_size
    elif tries >= 48 and tries < 64:
      if tries == 48:
        try_position = start_position
      if tries % 2 == 0:
        try_position.x -= tile_size
      else:
        try_position.y -= tile_size
    elif tries >= 96:
      print("WARNING: unable to place player!")
      positionValid = true
    tries += 1
  Player.position = try_position
  Map.add_to_tile(Player, Map.world_to_map(Player.position))
  Downstairs.position = (
    (end_room.position + Vector2(0, 1)).snapped(Vector2.ONE * tile_size)
    + Vector2(tile_size / 2, tile_size / 2)
  )
  Map.add_to_tile(Downstairs, Map.world_to_map(Downstairs.position))
  Map.Downstairs = Downstairs
  Upstairs.position = Player.position
  Map.add_to_tile(Upstairs, Map.world_to_map(Upstairs.position))
  Map.Upstairs = Upstairs
  $Camera.position = Player.position
  Player.load_persistence()
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
  var placed_corridor = false
  for x in range(pos1.x, pos2.x, x_diff):
    var cell = Map.get_cell(x, x_y.y)
    placed_corridor = false
    if not last_cell:
      last_cell = cell
    if cell == tile_empty: #or Map.get_cell_autotile_coord(x, x_y.y) != Vector2(1, 1):
      Map.set_cell(x, x_y.y, tile_corridor)
      VisibilityMap.set_cell(x, x_y.y, -1)
      placed_corridor = true
    elif (cell == tile_rooms and last_cell == tile_corridor):
      door_candidates.append(Vector2(x, x_y.y))
    last_cell = tile_corridor if placed_corridor else cell
  for y in range(pos1.y, pos2.y, y_diff):
    var cell = Map.get_cell(y_x.x, y)
    placed_corridor = false
    if cell == tile_empty: #or Map.get_cell_autotile_coord(y_x.x, y) != Vector2(1, 1):
      Map.set_cell(y_x.x, y, tile_corridor)
      VisibilityMap.set_cell(y_x.x, y, -1)
      placed_corridor = true
    elif (cell == tile_rooms and last_cell == tile_corridor):
      door_candidates.append(Vector2(y_x.x, y))
    last_cell = tile_corridor if placed_corridor else cell


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
