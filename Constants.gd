extends Node

onready var Random = preload("res://Random.gd").new()

enum DICE {
  d4 = 4,
  d6 = 6,
  d8 = 8,
  d10 = 10,
  d12 = 12,
  d20 = 20
 }

var directions = {
  "up": Vector2.UP,
  "right": Vector2.RIGHT,
  "down": Vector2.DOWN,
  "left": Vector2.LEFT
}

var GROUPS = {
  'HOSTILES': 'hostiles',
  'ALLIES': 'allies',
  'NEUTRALS': 'neutrals',
  'PLAYER': 'player',
  'ITEMS': 'items',
  'TRAPS': 'traps',
  'OBSTACLES': 'obstacles'
}

func roll_dice(die, count: int):
  var result = 0
  var minimum = count
  var maximum = count * die
  for _i in range(count):
    result += Random.rand_roll_int(minimum, maximum, 1.5)
  return result
