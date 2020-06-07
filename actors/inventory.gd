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

func drop(item):
  pass

func use(item):
  if item.type == Constants.ITEM_TYPE.weapon and "attack" in host:
    host.attack.arm_weapon(item, host.is_player)
  if item.type == Constants.ITEM_TYPE.item:
    pass

