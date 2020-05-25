extends KinematicBody2D

var tile_mover = preload("./actions/tile_mover.gd").new()

func _ready():
  tile_mover.host = self
  tile_mover.north_collider = $collider_north
  tile_mover.east_collider = $collider_east
  tile_mover.south_collider = $collider_south
  tile_mover.west_collider = $collider_west

func handle_order(order):
  if !("type" in order):
    pass
  match order.type:
    "move":
      tile_mover.move(order.payload)
