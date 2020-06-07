extends Control

var current_player
onready var health_bar: ProgressBar = $StatusContainer/StatusInnerContainer/HealthBar
onready var exp_level_label: Label = $StatusContainer/StatusInnerContainer/Level
onready var floor_level_label: Label = $FloorContainer/FloorInnerContainer/Floor
var ready = false

func _process(_delta):
  if health_bar and current_player and is_instance_valid(current_player):
    health_bar.max_value = current_player.mortality.max_hitpoints
    health_bar.value = current_player.mortality.hitpoints
    exp_level_label.text = "%d" % [current_player.level]
    floor_level_label.text = "%d" % [Game.current_floor]
