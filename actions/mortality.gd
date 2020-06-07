extends Node

onready var timer: Timer = $mortality_timer
var host
var hitpoints = 1
var max_hitpoints = 1
const HURT_COLOR = Color(1.0, 0.2, 0.2, 1.0)

func hurt(damage: int):
  hitpoints -= damage
  host.get_node("Sprite").set_modulate(HURT_COLOR)
  timer.start(0.18)
  if hitpoints < 0 and host:
    if "is_player" in host and host.is_player == true:
      MessageLog.log("You die...")
    else:
      MessageLog.log("The %s is killed!" % [host.nice_name])
    if host.has_method("die"):
      host.die()
    else:
      host.queue_free()


func _on_mortality_timer_timeout():
  host.get_node("Sprite").set_modulate(Color(1, 1, 1, 1))
