extends Control

func _on_Restart_pressed():
  Persistence.delete_save()
  Game.current_floor = 1
  Game.player_carry_over = null
  Scheduler.game_time = 0.0
  Scheduler.order_queue = []
  Scheduler.resolvable_orders = []
  Scheduler.order_completion_handlers = []
  MessageLog.messages = []
  get_tree().change_scene("res://level/World.tscn")


func _on_Quit_pressed():
  var level = get_tree().root.get_node("./Root/Game/World/")
  if level:
    Persistence.save_game(level.Player, level.Map)
  get_tree().quit()


func _on_Save_pressed():
  var level = get_tree().root.get_node("./Root/Game/World/")
  if level:
    Persistence.save_game(level.Player, level.Map)


func _on_Abandon_pressed():
  $AbandonDialog.popup()


func _on_AbandonDialog_confirmed():
  Persistence.delete_save()
  get_tree().quit()
