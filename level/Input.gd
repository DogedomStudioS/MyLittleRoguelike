extends Node

onready var current_player: KinematicBody2D = $"../Navigation2D/TileMap/Player"
onready var camera: Camera2D = $"../Camera"

var speed = 200.0
var velocity = Vector2(0, 0)

func _physics_process(delta):
	velocity = Vector2(0, 0)
	if Input.is_action_pressed("move_north"):
		velocity.y -= 1
	if Input.is_action_pressed("move_south"):
		velocity.y += 1
	if Input.is_action_pressed("move_east"):
		velocity.x += 1
	if Input.is_action_pressed("move_west"):
		velocity.x -= 1
		
	if current_player:
		current_player.move_and_slide(velocity.normalized() * speed)
		camera.position = current_player.position

func _input(event):
	pass
