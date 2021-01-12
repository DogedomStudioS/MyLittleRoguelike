extends KinematicBody2D

const obstacle_collision_layer = 513
var nice_name = "Door"
var map: TileMap
var closed = true

func _ready():
  add_to_group(Constants.GROUPS.DOORS)
  if closed:
    add_to_group(Constants.GROUPS.OBSTACLES)
    collision_mask = obstacle_collision_layer
    collision_layer = obstacle_collision_layer

func handle_action(action):
  if !("type" in action):
    pass
  match action.type:
    "toggle_door":
      toggle_door()

func toggle_door():
  if closed:
    _open_door()
  else:
    _close_door()

func _open_door():
  $Sprite.modulate.a = 0.4
  closed = false
  remove_from_group(Constants.GROUPS.OBSTACLES)
  collision_mask = 0
  collision_layer = 0

func _close_door():
  var tile_contents = map.get_tile_contents(map.world_to_map(position))
  if tile_contents.size() > 1:
    #something else is blocking the door
    return
  $Sprite.modulate.a = 1.0
  closed = true
  add_to_group(Constants.GROUPS.OBSTACLES)
  collision_mask = obstacle_collision_layer
  collision_layer = obstacle_collision_layer
