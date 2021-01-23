extends Node

onready var current_player: KinematicBody2D = $"../Navigation2D/TileMap/Player"
onready var map = $"../Navigation2D/TileMap"
onready var camera: Camera2D = $"../Camera"
onready var inventory_overlay = $"../../../UIViewport/Inventory"
onready var ingame_menu = $"../../../UIViewport/Menu"
onready var fog_of_war = $"../FogOfWar"
const MOVE_RETRY_DELAY = 0.21
var time_since_move = 0.0
var frozen_input = true

var action_prompt_mode = false
var action_prompt_action = {}
var action_prompt_valid_group = null

var speed = 200.0
var velocity = Vector2(0, 0)

func _door_opening_mode():
  action_prompt_mode = true
  action_prompt_action = {
    "type": "toggle_door",
    "player": true
  }

func _physics_process(delta):
  if frozen_input:
    return
  if current_player.dead:
    return
  if Input.is_action_just_pressed("ui_cancel"):
    if inventory_overlay.is_visible():
      inventory_overlay.set_visible(false)
    else:
      ingame_menu.set_visible(! ingame_menu.is_visible())
    return
  if Input.is_action_just_pressed("toggle_inventory"):
    if ! inventory_overlay.is_visible():
      inventory_overlay.show_inventory(current_player)
    inventory_overlay.set_visible(! inventory_overlay.is_visible())

  if inventory_overlay.is_visible():
    camera.position = current_player.get_node("Sprite").global_position
    return

  if Input.is_action_just_pressed("open_nearest_door"):
    var door = map.get_first_surrounding_node_in_group(current_player.position, Constants.GROUPS.DOORS)
    if door != null:
      Scheduler.handle_player_action(
        door,
        {
          'type': 'toggle_door',
          'payload': { 'target': door },
          'player': true
        }
      )

  var direction = null
  velocity = Vector2(0, 0)
  if Input.is_action_just_pressed("move_north"):
    direction = 'up'
  if Input.is_action_just_pressed("move_northeast"):
    direction = 'up_right'
  if Input.is_action_just_pressed("move_east"):
    direction = 'right'
  if Input.is_action_just_pressed("move_southeast"):
    direction = 'down_right'
  if Input.is_action_just_pressed("move_south"):
    direction = 'down'
  if Input.is_action_just_pressed("move_southwest"):
    direction = 'down_left'
  if Input.is_action_just_pressed("move_west"):
    direction = 'left'
  if Input.is_action_just_pressed("move_northwest"):
    direction = 'up_left'

  if (
    Input.is_action_pressed("move_north")
    or Input.is_action_pressed("move_northeast")
    or Input.is_action_pressed("move_east")
    or Input.is_action_pressed("move_southeast")
    or Input.is_action_pressed("move_south")
    or Input.is_action_pressed("move_southwest")
    or Input.is_action_pressed("move_west")
    or Input.is_action_pressed("move_northwest")
  ):
    time_since_move += delta
    if time_since_move > MOVE_RETRY_DELAY:
      time_since_move = 0.0
      if Input.is_action_pressed("move_north"):
        direction = 'up'
      if Input.is_action_pressed("move_northeast"):
        direction = 'up_right'
      if Input.is_action_pressed("move_east"):
        direction = "right"
      if Input.is_action_pressed("move_southeast"):
        direction = "down_right"
      if Input.is_action_pressed("move_south"):
        direction = 'down'
      if Input.is_action_pressed("move_southwest"):
        direction = 'down_left'
      if Input.is_action_pressed("move_west"):
        direction = 'left'
      if Input.is_action_pressed("move_northwest"):
        direction = 'up_left'
  else:
    time_since_move = 0.0
  if current_player and direction:
    var world_position = map.world_to_map(current_player.position)
    var destination = world_position + Constants.directions[direction]
    var tile_contents = map.get_tile_contents(destination)
    var did_attack = false
    for node in tile_contents:
      if is_instance_valid(node) and node.is_in_group(Constants.GROUPS.HOSTILES):
        did_attack = true
        Scheduler.handle_player_action(
          current_player,
          {
            'type': 'attack',
            'payload': {'target': node, 'direction': direction},
            'player': true
          }
        )
    if !did_attack:
      Scheduler.handle_player_action(current_player, {'type': 'move', 'payload': direction, 'player': true})
  if is_instance_valid(current_player):
    camera.position = current_player.get_node("Sprite").global_position
