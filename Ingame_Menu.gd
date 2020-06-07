extends Control

func _on_Restart_pressed():
  Game.current_floor = 1
  Game.player_carry_over = null
  Scheduler.game_time = 0.0
  Scheduler.order_queue = []
  Scheduler.resolvable_orders = []
  Scheduler.order_completion_handlers = []
  MessageLog.messages = []
  get_tree().change_scene("res://level/World.tscn")


func _on_Quit_pressed():
  get_tree().quit()
