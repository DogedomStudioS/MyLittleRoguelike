extends Node

var host: KinematicBody2D
onready var tween: Tween = $Tween
var tween_speed = 16
var weapon
var unarmed_damage = { "die": Constants.DICE.d4, "die_count": 1 }

func arm_weapon(new_weapon):
  weapon = new_weapon

func attack_damage():
  if weapon:
    return Constants.roll_dice(weapon.die, weapon.die_count)
  else:
    return Constants.roll_dice(unarmed_damage.die, unarmed_damage.die_count)

func attack(options):
  var target = options.target
  var direction = options.direction
  if 'mortality' in target:
    target.mortality.hurt(attack_damage())
    _animate_attack(direction)
  
func _animate_attack(direction):
  tween.connect("tween_completed", self, "_reverse_animation")
  tween.interpolate_property(
    host.get_node("Sprite"),
    "position",
    host.get_node("Sprite").position,
    Constants.directions[direction] * 6,
    1.0/tween_speed, Tween.TRANS_SINE, Tween.EASE_IN
  )
  tween.start()

func _reverse_animation(_object, _key):
  tween.interpolate_property(
    host.get_node("Sprite"),
    "position",
    host.get_node("Sprite").position,
    Vector2(0, 0),
    1.0/tween_speed, Tween.TRANS_SINE, Tween.EASE_OUT
  )
  tween.disconnect("tween_completed", self, "_reverse_animation")
  tween.start()
