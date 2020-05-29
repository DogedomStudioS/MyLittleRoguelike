extends Node

var host: KinematicBody2D
var tween: Tween
var tween_connected = false
var tile_size = 32
var moving = false
var north_collider: RayCast2D
var east_collider: RayCast2D
var south_collider: RayCast2D
var west_collider: RayCast2D
var moves_queue = []


var tween_speed = 5

var directions = {
  "up": Vector2.UP,
  "right": Vector2.RIGHT,
  "down": Vector2.DOWN,
  "left": Vector2.LEFT
}

func _tween_timeout(object, key):
  moving = false
  if moves_queue.size() > 0:
    move(moves_queue[0])
    moves_queue.pop_front()

func move_tween(direction):
    if not tween_connected:
      tween_connected = true
      tween.connect("tween_completed", self, "_tween_timeout")
    tween.interpolate_property(host, "position",
        host.position, host.position + direction * tile_size,
        1.0/tween_speed, Tween.TRANS_SINE, Tween.EASE_OUT)
    tween.start()

func move(direction: String):
  if moving == true and moves_queue.size() < 5:
    moves_queue.append(direction)
    return
  var blocked = false
  match direction:
    "up":
      blocked = north_collider.get_collider()
    "left":
      blocked = west_collider.get_collider()
    "down":
      blocked = south_collider.get_collider()
    "right":
      blocked = east_collider.get_collider()
  if blocked:
    return
  moving = true
  # right now we assume direction is one of Vector2.LEFT, Vector2.RIGHT etc.
  move_tween(directions[direction])
