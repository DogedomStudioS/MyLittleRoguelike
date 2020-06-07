extends KinematicBody2D

onready var mortality = $mortality
onready var tile_mover = $tile_mover
onready var attack = $attack
onready var inventory = $inventory
onready var tween = $Tween
const base_action_speed = 1.0
var modified_action_speed = 1.0
var is_player = true
var nice_name = "You"
var directional_animation = true
var move_animation = "bounces"

func _ready():
  add_to_group(Constants.GROUPS.PLAYER)
  inventory.host = self
  inventory.add(Items.weapons.club)
  attack.host = self
  mortality.host = self
  mortality.hitpoints = 20
  tile_mover.host = self
  tile_mover.tween = $Tween
  tile_mover.north_collider = $collider_north
  tile_mover.east_collider = $collider_east
  tile_mover.south_collider = $collider_south
  tile_mover.west_collider = $collider_west

func handle_action(action):
  if !("type" in action):
    pass
  match action.type:
    "move":
      tile_mover.move(action.payload)
    "attack":
      attack.attack(action.payload, true)
    "wield":
      attack.arm_weapon(action.payload, true)
