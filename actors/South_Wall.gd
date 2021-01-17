extends KinematicBody2D

var nice_name = "Wall"
var map: TileMap

onready var sprite = $Sprite

func _ready():
  add_to_group(Constants.GROUPS.STRUCTURES)

func tile_occupied(_node: Node2D):
  if _node != self:
    sprite.modulate.a = 0.4

func tile_abandoned(_node: Node2D):
  var tile_contents = map.get_tile_contents(map.world_to_map(position))
  if tile_contents.size() == 1:
    sprite.modulate.a = 1.0
  
