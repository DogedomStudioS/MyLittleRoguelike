extends Node

onready var current_player: KinematicBody2D = $"../Navigation2D/TileMap/Player"
onready var map: TileMap = $"../Navigation2D/TileMap"
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
var action_prompt_text = ""
var action_prompt_collision_layer = 0
var speed = 200.0
var velocity = Vector2(0, 0)

func _door_opening_mode():
  action_prompt_text = "Open or close a door in which direction?"
  action_prompt_mode = true
  action_prompt_action = {
    "type": "toggle_door",
    "player": true
  }
  action_prompt_valid_group = Constants.GROUPS.DOORS
  action_prompt_collision_layer = Constants.COLLISION_LAYERS.DOOR
  MessageLog.log(action_prompt_text)

func do_pickup():
  var tile_contents = map.get_tile_contents(map.world_to_map(current_player.position))
  for node in tile_contents:
    if node.is_in_group(Constants.GROUPS.ITEMS):
      Scheduler.handle_player_action(node, {
        "type": "pickup",
        "player": true,
        "payload": { "host": current_player }
      })
      MessageLog.log("Picked up %s." % [node.nice_name if "nice_name" in node else "an item"])
      return
  MessageLog.log("Nothing to pickup.")

func try_action_in_direction(direction):
  if not direction in Constants.directions.keys():
    MessageLog.log("Invalid direction.")
    MessageLog.log(action_prompt_text)
    return false
  var direction_vector = Constants.directions[direction]
  if action_prompt_collision_layer > 0:
    # create a raycast on the world server and try the direction.
    var collision = map.get_world_2d().direct_space_state.intersect_ray(
      current_player.position, 
      current_player.position + (Constants.directions[direction] * map.cell_size.x),
      [],
      action_prompt_collision_layer,
      true,
      true
    )
    if collision and collision.collider.is_in_group(action_prompt_valid_group):
      Scheduler.handle_player_action(collision.collider, action_prompt_action)
      cancel_action_prompt(false)
      return
  # Get tile contents in direction
  var tile_contents = map.get_tile_contents(map.world_to_map(current_player.position) + direction_vector)
  # Check for node in action_prompt_valid_group
  for node in tile_contents:
    if action_prompt_valid_group and node.is_in_group(action_prompt_valid_group):
      # if found, dispatch action_prompt_action with that node as the target
      Scheduler.handle_player_action(node, action_prompt_action)
      cancel_action_prompt(false)

func cancel_action_prompt(notify):
  action_prompt_text = ""
  action_prompt_mode = false
  action_prompt_action = {}
  action_prompt_valid_group = null
  action_prompt_collision_layer = 0
  if notify:
    MessageLog.log("Nevermind.")

func _physics_process(delta):
  if frozen_input or current_player.dead:
    return
  if Input.is_action_just_pressed("ui_cancel"):
    if action_prompt_mode:
      cancel_action_prompt(true)
      return
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

  if not action_prompt_mode and Input.is_action_just_pressed("open"):
    _door_opening_mode()
    return

  velocity = Vector2(0, 0)
  var direction = resolve_direction()

  if action_prompt_mode:
    if direction:
      try_action_in_direction(direction)
    return
  
  if Input.is_action_just_pressed("pickup"):
    do_pickup()

  if any_direction_pressed():
    time_since_move += delta
    if time_since_move > MOVE_RETRY_DELAY:
      time_since_move = 0.0
      direction = resolve_direction()
  else:
    time_since_move = 0.0
  if current_player and direction:
    var did_attack = try_attack(direction)
    if !did_attack:
      Scheduler.handle_player_action(current_player, {'type': 'move', 'payload': direction, 'player': true})
  if is_instance_valid(current_player):
    camera.position = current_player.get_node("Sprite").global_position

func try_attack(direction):
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
  return did_attack

func resolve_direction():
  var direction = null
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
  return direction

func any_direction_pressed():
  return (Input.is_action_pressed("move_north")
    or Input.is_action_pressed("move_northeast")
    or Input.is_action_pressed("move_east")
    or Input.is_action_pressed("move_southeast")
    or Input.is_action_pressed("move_south")
    or Input.is_action_pressed("move_southwest")
    or Input.is_action_pressed("move_west")
    or Input.is_action_pressed("move_northwest")
  )
