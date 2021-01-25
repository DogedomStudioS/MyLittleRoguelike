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
  }
}

var items = {
  "health_potion_small": {
    "label": "Small Healthpack",
    "icon": preload("res://assets/sprites/juice_box_pear.png"),
    "type": Constants.ITEM_TYPE.consumable,
    "properties": { "die": Constants.DICE.d4, "die_count": 3 },
    "on_use": funcref(self, "_use_health_item"),
    "drop": "Juice_Box_Pear"
  }
}

func _use_health_item(target, item):
  if target and "mortality" in target:
    var damage = Constants.roll_dice(item.properties.die, item.properties.die_count)
    target.mortality.heal(damage, true)