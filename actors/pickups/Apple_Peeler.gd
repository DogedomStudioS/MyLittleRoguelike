extends KinematicBody2D

var nice_name = "Apple Peeler"
var map: TileMap
var is_player = false
var item = Items.weapons.peeler

func _ready():
  add_to_group(Constants.GROUPS.ITEMS)

func handle_action(action):
  if !"type" in action:
    return
  match action.type:
    "pickup":
      _on_pickup(action.payload.host)

func _on_pickup(host):
  if host.inventory:
    host.inventory.add(item)
    if map:
      map.remove_from_tile(self, map.world_to_map(position))
      queue_free()
