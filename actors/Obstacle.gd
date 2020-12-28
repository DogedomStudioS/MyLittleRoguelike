extends KinematicBody2D

var nice_name = "Obstacle"
var map: TileMap


# Called when the node enters the scene tree for the first time.
func _ready():
  add_to_group(Constants.GROUPS.OBSTACLES)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#  pass
