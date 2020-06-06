extends Node

var weapon
var unarmed_damage = { "die": Constants.DICE.d4, "die_count": 1 }

func arm_weapon(weapon):
  weapon = weapon

func attack_damage():
  if weapon:
    return Constants.roll_dice(weapon.die, weapon.die_count)
  else:
    return unarmed_damage

func attack(target):
  pass
