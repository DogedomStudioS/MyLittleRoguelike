extends KinematicBody2D

var tile_mover = preload("./actions/tile_mover.gd").new()
const base_action_speed = 1.0
var modified_action_speed = 1.0

func _ready():
  tile_mover.host = self
  tile_mover.tween = $Tween
  tile_mover.north_collider = $collider_north
  tile_mover.east_collider = $collider_east
  tile_mover.south_collider = $collider_south
  tile_mover.west_collider = $collider_west

func handle_action(action):
  if !("type" in action):
    pass
  match action.type:
    "move":
      tile_mover.move(action.payload)
