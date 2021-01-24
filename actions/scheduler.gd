extends Node

var order_queue = []
var resolvable_orders = []
var order_completion_handlers = []
var game_time: float = 0.0
var entities = []

const order_times = {
    "move": 100,
    "attack": 75,
    "pickup": 50,
    "toggle_door": 50
}

func remove_entity(removed_entity):
  var index = entities.find(removed_entity)
  if index > -1:
    entities.remove(index)
      

func handle_player_action(target, action):
  var speed_modifier = target.modified_action_speed if ("modified_action_speed" in target) else 1.0
  var order_time = (order_times[action.type] * speed_modifier) if (action.type in order_times) else 100
  game_time += order_time / 100.0
  resolvable_orders.append({"target": target, "action": action})
  var index = 0
  var marked_for_removal = []
  for entity in entities:
    if not is_instance_valid(entity):
      marked_for_removal.append(index)
      index += 1
      pass
    var proposed_action = entity.get_next_action()
    var entity_speed_modifier = entity.modified_action_speed if "modified_action_speed" in entity else 1.0
    var entity_order_time = (order_times[action.type] * entity_speed_modifier) if (action.type in order_times) else 100
    if entity_order_time * 0.01 <= game_time - entity.last_action_time:
      resolvable_orders.append({ "target": entity, "action": proposed_action})
      entity.last_action_time = game_time
    index += 1
  if marked_for_removal.size() > 0:
    var valid_entities = []
    for i in range(0, entities.size()):
      if marked_for_removal.find(i) < 0:
        valid_entities.append(entities[i])
    entities = valid_entities
  for handler in order_completion_handlers:
    handler.orders_handled(game_time)
  MessageLog.refresh_display()


func submit(target, action):
  pass
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
