extends Node

onready var Random = preload("res://Random.gd").new()

enum DICE { d4 = 4, d6 = 6, d8 = 8, d10 = 10, d12 = 12, d20 = 20 }

var directions = {
  "up": Vector2.UP,
  "up_right": Vector2.UP + Vector2.RIGHT,
  "right": Vector2.RIGHT,
  "down_right": Vector2.DOWN + Vector2.RIGHT,
  "down": Vector2.DOWN,
  "down_left": Vector2.DOWN + Vector2.LEFT,
  "left": Vector2.LEFT,
  "up_left": Vector2.UP + Vector2.LEFT
}

var COLLISION_LAYERS = {
  "SOLID": 1,
  "OBSTACLE": 512,
  "DOOR": 1024
}

var GROUPS = {
  'HOSTILES': 'hostiles',
  'ALLIES': 'allies',
  'NEUTRALS': 'neutrals',
  'PLAYER': 'player',
  'ITEMS': 'items',
  'TRAPS': 'traps',
  'OBSTACLES': 'obstacles',
  'DOORS': 'doors',
  'STRUCTURES': 'structures'
}

enum ITEM_TYPE { weapon, item, consumable, apple_piece }


func roll_dice(die, count: int):
  var result = 0
  var minimum = count
  var maximum = count * die
  for _i in range(count):
    result += Random.rand_roll_int(minimum, maximum, 1.5)
  return result
