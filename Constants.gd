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

var MESSAGES = {
  "green_apple_weapon_hint_kill": "You are unable to harvest the Green Apple's slices. Try using a more precise weapon!",
  "green_apple_weapon_kill_success": "The peeler cuts off a perfect slice of Green Apple!",
  "yellow_apple_weapon_hint_attack": "The Yellow Apple's skin is very tough!",
  "yellow_apple_weapon_hint_kill": "You are unable to harvest the Yellow Apple's slices. Try a longer weapon!",
  "yellow_apple_weapon_kill_success": "The corer leaves behind a perfect slice of Yellow Apple!",
  "pink_apple_weapon_hint_attack": "Your attack barely hurts the Pink Apple!",
  "pink_apple_weapon_hint_kill": "You are unable to harvest the Pink Apple's slices. Try a sharper weapon!"
}


func roll_dice(die, count: int):
  var result = 0
  var minimum = count
  var maximum = count * die
  for _i in range(count):
    result += Random.rand_roll_int(minimum, maximum, 1.5)
  return result
