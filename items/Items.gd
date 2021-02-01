extends Node

var weapons = {
  "club": {
    "label": "Club",
    "type": Constants.ITEM_TYPE.weapon,
    "icon": preload("res://assets/sprites/weapon_club.png"),
    "properties": { "die": Constants.DICE.d6, "die_count": 1 }
  },
  "spork": {
    "label": "Spork",
    "icon": preload("res://assets/sprites/weapon_spork.png"),
    "type": Constants.ITEM_TYPE.weapon,
    "properties": { "die": Constants.DICE.d4, "die_count": 2 }
  },
  "peeler": {
    "label": "Peeler",
    "type": Constants.ITEM_TYPE.weapon,
    "icon": preload("res://assets/sprites/apple_peeler.png"),
    "properties": { "die": Constants.DICE.d6, "die_count": 1 } 
  },
  "corer": {
    "label": "Corer",
    "type": Constants.ITEM_TYPE.weapon,
    "icon": preload("res://assets/sprites/apple_corer.png"),
    "properties": { "die": Constants.DICE.d8, "die_count": 1 }
  }
}

var items = {
  "health_potion_small": {
    "label": "Small Healthpack",
    "icon": preload("res://assets/sprites/juice_box_pear.png"),
    "type": Constants.ITEM_TYPE.consumable,
    "properties": { "die": Constants.DICE.d4, "die_count": 2 },
    "on_use":  "use_health_item",
    "drop": "Juice_Box_Pear"
  },
  "green_apple_slice": {
    "label": "Green Apple Slice",
    "icon": preload("res://assets/sprites/green_apple_slice_sprite.png"),
    "type": Constants.ITEM_TYPE.apple_piece,
    "properties": {},
    "drop": "Green_Apple_Slice"
  },
  "yellow_apple_slice": {
    "label": "Yellow Apple Slice",
    "icon": preload("res://assets/sprites/yellow_apple_slice.png"),
    "type": Constants.ITEM_TYPE.apple_piece,
    "properties": {},
    "drop": "Yellow_Apple_Slice"
  }
}

func use_health_item(target, item):
  if target and "mortality" in target:
    var damage = Constants.roll_dice(int(item.properties.die), item.properties.die_count)
    print(damage)
    target.mortality.heal(damage, true)
