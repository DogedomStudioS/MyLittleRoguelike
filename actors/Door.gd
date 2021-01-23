extends KinematicBody2D

var nice_name = "Door"
var map: TileMap
var closed = true
var last_action_time = 0

onready var collisions_open = Constants.COLLISION_LAYERS.DOOR
onready var collisions_closed = Constants.COLLISION_LAYERS.SOLID + Constants.COLLISION_LAYERS.OBSTACLE + Constants.COLLISION_LAYERS.DOOR
onready var sprite: AnimatedSprite = $AnimatedSprite

func _ready():
  add_to_group(Constants.GROUPS.DOORS)
  if closed:
    sprite.play("closed")
    add_to_group(Constants.GROUPS.OBSTACLES)
    collision_mask = collisions_closed
    collision_layer = collisions_closed
  else:
    sprite.play("open")
    collision_mask = collisions_open
    collision_layer = collisions_open

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
  sprite.play("open")
  closed = false
  remove_from_group(Constants.GROUPS.OBSTACLES)
  collision_mask = collisions_open
  collision_layer = collisions_open
  if map:
    map.fog_of_war.shadow_map_dirty = true

func _close_door():
  sprite.play("closed")
  closed = true
  add_to_group(Constants.GROUPS.OBSTACLES)
  collision_mask = collisions_closed
  collision_layer = collisions_closed
  if map:
    map.fog_of_war.shadow_map_dirty = true
