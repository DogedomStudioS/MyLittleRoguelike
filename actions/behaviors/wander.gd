extends Node
# AI behavior that queues a random walk action.

onready var tile_mover = $"../tile_mover"
var initialized = false
var directions = ["up", "left", "down", "right"]

func _ready():
  if not tile_mover:
    print("behavior 'wander' can only apply to entities implementing tile_mover.")
    return
  initialized = true

func handle_action(action):
  if initialized and action.type == "move":
    tile_mover.move(action.payload)

func generate_next_action():
  var direction = randi() % 4
  return {
    "type": "move",
    "payload": directions[direction]
  }
