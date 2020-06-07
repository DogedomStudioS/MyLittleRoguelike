extends Node

var host
var hitpoints = 1
var max_hitpoints = 1

func hurt(damage: int):
  hitpoints -= damage
  if "is_player" in host and host.is_player == true:
    MessageLog.log("The %s hits!" % [host.nice_name])
  if hitpoints < 0 and host:
    if "is_player" in host and host.is_player == true:
      MessageLog.log("You die...")
    else:
      MessageLog.log("The %s is killed!" % [host.nice_name])
    if host.has_method("die"):
      host.die()
    else:
      host.queue_free()
