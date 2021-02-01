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
var dead = false
var map = null

var experience = 0
var level = 1
const EXP_PER_LEVEL = 85
var moves_per_exp = 100
var last_movement_exp_gain_time = 0.0

const HITPOINTS_PER_LEVEL = 3
const HEALTH_REGENERATION_DELAY = 38
var last_health_regeneration_time = 0.0

func _ready():
  add_to_group(Constants.GROUPS.PLAYER)
  inventory.host = self
  inventory.add(Items.items.health_potion_small)
  attack.host = self
  mortality.host = self
  mortality.max_hitpoints = 25
  mortality.hitpoints = 25
  tile_mover.host = self
  tile_mover.tween = $Tween
  tile_mover.north_collider = $collider_north
  tile_mover.northeast_collider = $collider_northeast
  tile_mover.east_collider = $collider_east
  tile_mover.southeast_collider = $collider_southeast
  tile_mover.south_collider = $collider_south
  tile_mover.southwest_collider = $collider_southwest
  tile_mover.west_collider = $collider_west
  tile_mover.northwest_collider = $collider_northwest
  Scheduler.order_completion_handlers.append(self)

func load_persistence():
  if Game.player_carry_over:
    var carry_over = Game.player_carry_over
    mortality.max_hitpoints = carry_over.max_hp
    mortality.hitpoints = carry_over.hitpoints
    experience = carry_over.experience
    level = carry_over.level
    last_movement_exp_gain_time = carry_over.last_movement_exp_gain_time
    last_health_regeneration_time = carry_over.last_health_regeneration_time
    inventory.weapons = carry_over.weapons
    inventory.items = carry_over.items
    if "weapon" in carry_over:
      attack.arm_weapon(carry_over.weapon, false)
  
func die():
  tile_mover.map.remove_from_tile(self, tile_mover.map.world_to_map(self.position))
  dead = true
  $Sprite.set_visible(false)
  $"../../../../../UIViewport/Menu".set_visible(true)

func change_level(floor_number: int):
  Game.current_floor = floor_number
  Game.player_carry_over = {
    "hitpoints": mortality.hitpoints,
    "max_hp": mortality.max_hitpoints,
    "experience": experience,
    "level": level,
    "last_movement_exp_gain_time": last_movement_exp_gain_time,
    "last_health_regeneration_time": last_health_regeneration_time,
    "weapon": attack.weapon,
    "weapons": inventory.weapons,
    "items": inventory.items
  }
  Scheduler.game_time = 0.0
  Scheduler.entities = []
  Scheduler.order_queue = []
  Scheduler.resolvable_orders = []
  Scheduler.order_completion_handlers = []
  MessageLog.messages = []
  get_tree().change_scene("res://level/World.tscn")

func handle_action(action):
  if !("type" in action):
    pass
  match action.type:
    "move":
      tile_mover.move(action.payload)
      if get_parent().check_for_node_at_location(get_parent().Downstairs, position):
        #change_level(Game.current_floor + 1)
        MessageLog.log("You are on the stairs to the next floor.")
      if get_parent().check_for_node_at_location(get_parent().Upstairs, position):
        MessageLog.log("You are on the stairs to the previous floor.")
    "attack":
      experience += 3
      attack.attack(action.payload, true)
    "wield":
      attack.arm_weapon(action.payload, true)

func orders_handled(game_time):
  if game_time - last_movement_exp_gain_time > moves_per_exp:
    last_movement_exp_gain_time = game_time
    experience += 1
  if game_time - last_health_regeneration_time > HEALTH_REGENERATION_DELAY:
    last_health_regeneration_time = game_time
    mortality.hitpoints += 1
    if mortality.hitpoints > mortality.max_hitpoints:
      mortality.hitpoints = mortality.max_hitpoints
  if experience > EXP_PER_LEVEL + (level * EXP_PER_LEVEL * 0.3):
    level += 1
    MessageLog.log("You gained a level! Welcome to level %d" % [level])
    if level % 2 == 0:
      attack.bonus_damage += 1
    mortality.max_hitpoints += HITPOINTS_PER_LEVEL
    mortality.hitpoints += mortality.max_hitpoints / 4
    if mortality.hitpoints > mortality.max_hitpoints:
      mortality.hitpoints = mortality.max_hitpoints
