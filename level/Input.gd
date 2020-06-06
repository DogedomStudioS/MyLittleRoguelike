extends Node

onready var current_player: KinematicBody2D = $"../Navigation2D/TileMap/Player"
onready var map = $"../Navigation2D/TileMap"
onready var camera: Camera2D = $"../Camera"

var speed = 200.0
var velocity = Vector2(0, 0)

func _physics_process(_delta):
  var direction = null
  velocity = Vector2(0, 0)
  if Input.is_action_just_pressed("move_north"):
    direction = 'up'
  if Input.is_action_just_pressed("move_south"):
    direction = 'down'
  if Input.is_action_just_pressed("move_east"):
    direction = 'right'
  if Input.is_action_just_pressed("move_west"):
    direction = 'left'
  
  if current_player and direction:
    var world_position = map.world_to_map(current_player.position)
    var destination = world_position + Constants.directions[direction]
    var tile_contents = map.get_tile_contents(destination)
    for node in tile_contents:
      if is_instance_valid(node) and node.is_in_group(Constants.GROUPS.HOSTILES):
        Scheduler.submit(current_player, {
          'type': 'attack',
          'payload': {
            'target': node,
            'direction': direction
          },
          'player': true
        })
        return
    Scheduler.submit(current_player, {
      'type': 'move',
      'payload': direction,
      'player': true
    })
  camera.position = current_player.get_node("Sprite").global_position
