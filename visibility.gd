extends TileMap

onready var level_map: TileMap = $"../Navigation2D/TileMap"
onready var player = $"../Navigation2D/TileMap/Player"

var sight_radius = 12
var space_state
var tile_size = 32
var last_position = Vector2(-1, -1)
var last_center_tile = Vector2(0, 0)
#var hits = []
#var rays = []
var shadow_map_dirty = false
var debug_color = Color(1.0, 0.0, 0.0, 1.0)


func _ready():
  space_state = player.get_world_2d().direct_space_state


func _physics_process(_delta):
  if ! is_instance_valid(player):
    return
  if shadow_map_dirty:
    update_visibility(last_center_tile)
    update()
    level_map.update_visibility()
    shadow_map_dirty = false
  if world_to_map(player.position) != last_position:
    shadow_map_dirty = true
    space_state = get_world_2d().direct_space_state
    var new_player_position = player.position
    var player_tile = world_to_map(new_player_position)
    var center_tile = Vector2(
      (player_tile.x * tile_size) + 16, (player_tile.y * tile_size) + 16
    )
    $"../Player Eyes".position = center_tile
    update()
    last_center_tile = center_tile
    last_position = world_to_map(player.position)


func update_visibility(from: Vector2):
  var tile_position = from
  var collision
  var cell
  #hits = []
  #rays = []
  for x in range(-sight_radius, sight_radius + 1):
    for y in range(-sight_radius, sight_radius + 1):
      tile_position.x = from.x + (x * tile_size)
      tile_position.y = from.y + (y * tile_size)
      collision = space_state.intersect_ray(tile_position, from, [], 512, true, true)
      cell = get_cellv(world_to_map(tile_position))
      #if collision and x > -3 and x < 3 and y > -3 and y < 3:
        #rays.append([tile_position, collision.position])
      if collision and collision.collider.name == 'Player Eyes':
        #hits.append(tile_position)
        if (
          level_map.get_cellv(world_to_map(tile_position)) == 2
          and tile_position.distance_to(from) > 45
        ):
          set_cellv(world_to_map(tile_position), 0)
        else:
          set_cellv(world_to_map(tile_position), -1)
      else:
        if cell != 0:
          set_cellv(world_to_map(tile_position), 0)
  set_cellv(world_to_map(from), -1)

#func _draw():
#  draw_circle(last_center_tile, 15.0, Color(0.0, 1.0, 0.0, 0.4))
#  for ray in rays:
#    draw_line(ray[0], ray[1], debug_color, 1.0)
#    draw_circle(ray[1], 3.0, Color(0.0, 1.0, 0.0, 1.0))
