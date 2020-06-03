extends Node

onready var current_player: KinematicBody2D = $"../Navigation2D/TileMap/Player"
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
    Scheduler.submit(current_player, {
      'type': 'move',
      'payload': direction,
      'player': true
    })
  camera.position = current_player.get_node("Sprite").global_position
