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
