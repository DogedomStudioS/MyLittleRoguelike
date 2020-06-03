extends TileMap

var claimed_move_targets = []

func _ready():
  Scheduler.order_completion_handlers.append(self)

func orders_handled(_game_time):
  claimed_move_targets.clear()
