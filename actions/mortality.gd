extends Node

var host
var hitpoints = 1

func hurt(damage: int):
  print("%s hit for %d damage" % [host.get_name(), damage])
  hitpoints -= damage
  if hitpoints < 0 and host:
    if host.has_method("die"):
      host.die()
    else:
      host.queue_free()
