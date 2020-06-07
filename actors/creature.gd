extends KinematicBody2D

onready var wander = $wander
onready var tile_mover = $tile_mover
onready var mortality = $mortality
onready var tween = $Tween

var nice_name = "Creature"
const base_action_speed = 1.8
var modified_action_speed = 1.8
var behaviors
var is_player = false
var directional_animation = false

func _ready():
  add_to_group(Constants.GROUPS.HOSTILES)
  mortality.hitpoints = 5
  mortality.host = self
  tile_mover.host = self
  tile_mover.tween = $Tween
  tile_mover.north_collider = $collider_north
  tile_mover.east_collider = $collider_east
  tile_mover.south_collider = $collider_south
  tile_mover.west_collider = $collider_west
  behaviors = [wander]
  Scheduler.submit(self, get_next_action())

func die():
  tile_mover.map.remove_from_tile(self, tile_mover.map.world_to_map(self.position))
  queue_free()

func handle_action(order):
  for behavior in behaviors:
    behavior.handle_action(order)
  Scheduler.submit(self, get_next_action())

func get_next_action():
  # simple as can be, for now - just check if the player is adjacent and attack if so
  return wander.generate_next_action()
