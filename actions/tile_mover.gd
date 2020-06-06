extends Node

var host: KinematicBody2D
var tween: Tween
var map: TileMap
var tween_connected = false
var tile_size = 32
var moving = false
var north_collider: RayCast2D
var east_collider: RayCast2D
var south_collider: RayCast2D
var west_collider: RayCast2D
var moves_queue = []
var initialized = false
var destination_index = -1

var tween_speed = 5

func _tween_timeout(_object, _key):
  moving = false
  if moves_queue.size() > 0:
    if check_blocked(moves_queue[0]) == null:
      Scheduler.submit(host, { "type": "move", "payload": moves_queue[0], "player": true })
    moves_queue.pop_front()

func move_tween():
  #if not tween_connected:
  #  tween_connected = true
  #  tween.connect("tween_completed", self, "_tween_timeout")
  tween.interpolate_property(
    host.get_node("Sprite"),
    "position",
    host.get_node("Sprite").position,
    Vector2(0, 0),
    1.0/tween_speed, Tween.TRANS_SINE, Tween.EASE_OUT
  )
  tween.start()

func check_blocked(direction):
  var blocked = null
  match direction:
    "up":
      blocked = north_collider.get_collider()
    "left":
      blocked = west_collider.get_collider()
    "down":
      blocked = south_collider.get_collider()
    "right":
      blocked = east_collider.get_collider()
  return blocked

func move(direction: String):
  if moving == true and moves_queue.size() < 3:
    #moves_queue.append(direction)
    return
  if not map and host.get_parent().get_class() == 'TileMap':
    map = host.get_parent()
  var destination = host.position + Constants.directions[direction] * tile_size
  var blocked = check_blocked(direction) or destination in map.claimed_move_targets
  if blocked:
    return
  if map:
    map.claimed_move_targets.append(destination)
  moving = true
  # right now we assume direction is one of Vector2.LEFT, Vector2.RIGHT etc.
  var previous_position = host.position
  host.position = destination
  map.remove_from_tile(host, map.world_to_map(previous_position))
  host.get_node("Sprite").position -= Constants.directions[direction] * tile_size
  map.add_to_tile(host, map.world_to_map(destination), map.world_to_map(previous_position))
  moving = false
  move_tween()
