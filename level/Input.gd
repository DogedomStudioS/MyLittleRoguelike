extends Node

onready var current_player: KinematicBody2D = $"../Navigation2D/TileMap/Player"
onready var map = $"../Navigation2D/TileMap"
onready var camera: Camera2D = $"../Camera"
onready var inventory_overlay = $"../../../UIViewport/Inventory"
onready var ingame_menu = $"../../../UIViewport/Menu"
const MOVE_RETRY_DELAY = 0.21
var time_since_move = 0.0
var frozen_input = true

var speed = 200.0
var velocity = Vector2(0, 0)

func _physics_process(delta):
  if frozen_input:
    return
  if current_player.dead:
    return
  if Input.is_action_just_pressed("ui_cancel"):
    if inventory_overlay.is_visible():
      inventory_overlay.set_visible(false)
    else:
      ingame_menu.set_visible(!ingame_menu.is_visible())
    return
  if Input.is_action_just_pressed("toggle_inventory"):
    if !inventory_overlay.is_visible():
      inventory_overlay.show_inventory(current_player)
    inventory_overlay.set_visible(!inventory_overlay.is_visible())
  
  if inventory_overlay.is_visible():
    camera.position = current_player.get_node("Sprite").global_position
    return

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

  if Input.is_action_pressed("move_north") or Input.is_action_pressed("move_east") or Input.is_action_pressed("move_south") or Input.is_action_pressed("move_west"):
    time_since_move += delta
    if time_since_move > MOVE_RETRY_DELAY:
      time_since_move = 0.0
      if Input.is_action_pressed("move_north"):
        direction = 'up'
      if Input.is_action_pressed("move_south"):
        direction = 'down'
      if Input.is_action_pressed("move_east"):
        direction = 'right'
      if Input.is_action_pressed("move_west"):
        direction = 'left'
  else:
    time_since_move = 0.0
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
        
    Scheduler.submit(current_player, {
      'type': 'move',
      'payload': direction,
      'player': true
    })
  if is_instance_valid(current_player):
    camera.position = current_player.get_node("Sprite").global_position
