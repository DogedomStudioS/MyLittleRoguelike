extends Node

var host: KinematicBody2D
var tile_size = 32
var moving = false
var north_collider: RayCast2D
var east_collider: RayCast2D
var south_collider: RayCast2D
var west_collider: RayCast2D

var directions = {
  "up": Vector2.UP,
  "right": Vector2.RIGHT,
  "down": Vector2.DOWN,
  "left": Vector2.LEFT
}

func move(direction: String):
  if moving:
    pass
  var blocked = false
  match direction:
    "up":
      blocked = north_collider.get_collider()
    "left":
      blocked = west_collider.get_collider()
    "down":
      south_collider.force_raycast_update()
      blocked = south_collider.get_collider()
    "right":
      blocked = east_collider.get_collider()
  if blocked:
    print('blocked.')
    return
  moving = true
  # right now we assume direction is one of Vector2.LEFT, Vector2.RIGHT etc.
  host.position = host.position + (directions[direction] * tile_size)
