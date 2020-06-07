extends Node

const MESSAGE_TIMEOUT = 10
var messages = []
var display_messages = []
var message_labels = []

var message_colors = {
  "new": Color(1, 1, 1, 1),
  "old": Color(0.7, 0.7, 0.7, 1),
  "fading": Color(0.4, 0.4, 0.4, 1)
}

func log(message: String):
  messages.push_front({ "message": message, "time": Scheduler.game_time })
  refresh_display()

func refresh_display():
  var current_time = Scheduler.game_time
  check_message_timeouts()
  var labels = []
  for i in range(message_labels.size()):
    if i < display_messages.size():
      labels.push_front(message_labels[i])
  for i in range(labels.size()):
    var age = current_time - display_messages[i].time
    if age >= MESSAGE_TIMEOUT / 2.0 and age < MESSAGE_TIMEOUT - 2:
      labels[i].add_color_override("font_color", message_colors.old)
    elif age >= MESSAGE_TIMEOUT - 2:
      labels[i].add_color_override("font_color", message_colors.fading)
    else:
      labels[i].add_color_override("font_color", message_colors.new)
    labels[i].text = display_messages[i].message
  if labels.size() < message_labels.size():
    for j in range(message_labels.size()):
      if j >= labels.size():
        message_labels[j].text = ""

func check_message_timeouts():
  display_messages = []
  var current_time = Scheduler.game_time
  for message in messages:
    if current_time - message.time < MESSAGE_TIMEOUT:
      display_messages.append(message)
