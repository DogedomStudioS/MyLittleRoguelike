extends Node

var host
var hitpoints = 1

func hurt(damage: int):
  hitpoints -= damage
  if hitpoints < 0 and host:
    if host.has_method("die"):
      host.die()
    else:
      host.queue_free()
