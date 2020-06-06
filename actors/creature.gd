extends KinematicBody2D

onready var wander = $wander
onready var tile_mover = $tile_mover
onready var mortality = $mortality
const base_action_speed = 1.4
var modified_action_speed = 1.4
var behaviors

func _ready():
  mortality.hitpoints = 5
  tile_mover.host = self
  tile_mover.tween = $Tween
  tile_mover.north_collider = $collider_north
  tile_mover.east_collider = $collider_east
  tile_mover.south_collider = $collider_south
  tile_mover.west_collider = $collider_west
  behaviors = [wander]
  Scheduler.submit(self, wander.generate_next_action())

func die():
  queue_free()

func handle_action(order):
  for behavior in behaviors:
    behavior.handle_action(order)
  Scheduler.submit(self, get_next_action())

func get_next_action():
  return wander.generate_next_action()
