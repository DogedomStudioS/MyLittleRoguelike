extends Node

#item: {
#	label: String,
#	type: ITEM_TYPE,
#	properties: Dictionary # would be weapon properties for a weapon, etc.
#}

var host
var weapons = [] #[weapon]
var items = [] #[item]
var apples = [] #[apple_piece]
var weapons_capacity: int = 5
var capacity: int = 5

func add(item, you = false):
  match item.type:
    Constants.ITEM_TYPE.weapon:
      if weapons.size() < weapons_capacity:
        weapons.append(item)
        if you:
          MessageLog.log("Picked up %s" % [item.label])
      else:
        if you:
          MessageLog.log("Inventory full. Drop some weapons to clear slots.")
    Constants.ITEM_TYPE.item:
      pass
    Constants.ITEM_TYPE.apple_piece:
      pass
    Constants.ITEM_TYPE.consumable:
      items.append(item)
      if you:
        MessageLog.log("Picked up %s" % [item.label])

func drop(item):
  if "drop" in item and "map" in host:
    var new_item_type = load("res://actors/pickups/%s.tscn" % [item.drop])
    var map = host.map
    if new_item_type:
      var new_item = new_item_type.instance()
      new_item.map = map
      map.add_child(new_item)
      new_item.position = host.position.snapped(Vector2.ONE * map.cell_size) - Vector2(map.cell_size.x / 2, map.cell_size.x / 2)
      map.add_to_tile(new_item, map.world_to_map(new_item.position))

func remove_item(index):
  items.remove(index)

func use(item):
  if item.type == Constants.ITEM_TYPE.weapon and "attack" in host:
    host.attack.arm_weapon(item, host.is_player)
  if item.type == Constants.ITEM_TYPE.item:
    pass


