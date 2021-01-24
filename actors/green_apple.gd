extends KinematicBody2D

onready var wander = $wander
onready var tile_mover = $tile_mover
onready var mortality = $mortality
onready var attack = $attack
onready var tween = $Tween

var nice_name = "Green Apple"
var map: TileMap
var last_action_time = 0
const base_action_speed = 1.4
var modified_action_speed = 1.4
var behaviors
var is_player = false
var directional_animation = true
var move_animation = "bounces"

func _ready():
  add_to_group(Constants.GROUPS.HOSTILES)
  attack.host = self
  mortality.hitpoints = 10
  mortality.max_hitpoints = 10
  mortality.host = self
  tile_mover.host = self
  tile_mover.tween = $Tween
  tile_mover.north_collider = $collider_north
  tile_mover.east_collider = $collider_east
  tile_mover.south_collider = $collider_south
  tile_mover.west_collider = $collider_west
  behaviors = [wander]
  Scheduler.entities.append(self)

func die():
  if tile_mover.map:
    tile_mover.map.remove_from_tile(self, tile_mover.map.world_to_map(self.position))
  Scheduler.remove_entity(self)
  queue_free()

func handle_action(action):
  for behavior in behaviors:
    behavior.handle_action(action)
  if action.type == 'attack':
    attack.attack(action.payload, false)

func get_next_action():
  if map:
    var players = get_tree().get_nodes_in_group(Constants.GROUPS.PLAYER)
    if players.size() > 0:
      var player_search = map.check_surrounding_tiles_for_node(players[0], position)
      if player_search.found == true:
        return {
          'type': 'attack',
          'payload': {
            'target': players[0],
            'direction': player_search.direction
          },
          'player': false
        }
  return wander.generate_next_action()
