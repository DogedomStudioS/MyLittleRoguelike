extends Node

var order_queue = []
var resolvable_orders = []
var order_completion_handlers = []
var game_time: float = 0.0

const order_times = {
    "move": 100,
    "attack": 75
}


func submit(target, action):
  var speed_modifier = target.modified_action_speed if ("modified_action_speed" in target) else 1.0
  var order_time = (order_times[action.type] * speed_modifier) if (action.type in order_times) else 100
  order_queue.append({ "target": target, "action": action, "time": order_time })
  if "player" in action and action.player == true:
    handle_orders(order_time)
    game_time += order_time / 100.0

func handle_orders(time):
  var in_progress_orders = []
  for order in order_queue:
    order.time = order.time - time
    if order.time <= 0:
      resolvable_orders.append(order)
    else:
      in_progress_orders.append(order)
  order_queue = in_progress_orders
  for handler in order_completion_handlers:
    handler.orders_handled(game_time)
  MessageLog.refresh_display()

func _physics_process(_delta):
  for order in resolvable_orders:
    if is_instance_valid(order.target):
      order.target.handle_action(order.action)
  resolvable_orders = []
