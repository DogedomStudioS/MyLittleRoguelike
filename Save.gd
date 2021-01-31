extends Node

const game_save_path = "user://game.avosave"

func save_game(player, level):
  var weapons = []
  var items = []
  for weapon in player.inventory.weapons:
    var icon = weapon.icon
    if typeof(icon) != TYPE_STRING:
      icon = weapon.icon.resource_path
    weapons.append({
      "label": weapon.label,
      "icon": icon,
      "type": weapon.type,
      "properties": weapon.properties
    })
  for item in player.inventory.items:
    var icon = item.icon
    if typeof(icon) != TYPE_STRING:
      icon = item.icon.resource_path
    items.append({
      "label": item.label,
      "icon": icon,
      "type": item.type,
      "properties": item.properties,
      "on_use": item.on_use,
      "drop": item.drop
    })
  var player_weapon = null
  if player.attack.weapon:
    var icon = player.attack.weapon.icon
    if typeof(icon) != TYPE_STRING:
      icon = player.attack.weapon.resource_path
    player_weapon = {
      "label": player.attack.weapon.label,
      "type": player.attack.weapon.type,
      "icon": icon,
      "properties": player.attack.weapon.properties
    }
  var player_state = {
    "hitpoints": player.mortality.hitpoints,
    "max_hp": player.mortality.max_hitpoints,
    "experience": player.experience,
    "level": player.level,
    "last_movement_exp_gain_time": player.last_movement_exp_gain_time,
    "last_health_regeneration_time": player.last_health_regeneration_time,
    "weapons": weapons,
    "items": items,
    "x": level.world_to_map(player.position).x,
    "y": level.world_to_map(player.position).y,
  }
  if player_weapon:
    player_state.weapon = player_weapon
  var game_state = {
    "highest_level": Game.highest_level,
    "current_floor": Game.current_floor
  }
  var game_save_directory = Directory.new()
  game_save_directory.remove(game_save_path)
  var game_save = File.new()
  print(OS.get_user_data_dir())
  game_save.open(game_save_path, File.WRITE)
  game_save.store_line(to_json(game_state))
  game_save.store_line(to_json(player_state))
  game_save_directory.remove("user://level%d.avosave" % [Game.current_floor])
  save_level(level)
  MessageLog.log("Game Saved.")
  game_save.close()

func save_level(level):
  # first get the metadata as per documentation
  # Then store the tile IDs as a giant CSV value
  var rooms = []
  var room_index = 0
  for room_position in level.room_positions:
    rooms.append({
      "position_x": room_position.x,
      "position_y": room_position.y,
      "size_x": level.room_sizes[room_index].x,
      "size_y": level.room_sizes[room_index].y
    })
    room_index += 1
  var tile_string = ""
  var topleft = level.topleft
  var bottomright = level.bottomright
  for x in range(topleft.x, bottomright.x):
    for y in range(topleft.y, bottomright.y):
      tile_string += "%d,%d,%d," % [x, y, level.get_cell(x, y)]
  var level_data = {
    "topleft_x": topleft.x,
    "topleft_y": topleft.y,
    "bottomright_x": bottomright.x,
    "bottomright_y": bottomright.y,
    "downstairs_x": level.world_to_map(level.Downstairs.position).x,
    "downstairs_y": level.world_to_map(level.Downstairs.position).y,
    "rooms": rooms,
    "tiles": tile_string,
    "entities": get_saved_entities(level)
   }
  
  var level_save = File.new()
  level_save.open("user://level%d.avosave" % [Game.current_floor], File.WRITE)
  level_save.store_line(to_json(level_data))
  level_save.close()

func get_saved_entities(level):
  # We will use groups to sort these.
  var creatures = get_tree().get_nodes_in_group(Constants.GROUPS.HOSTILES)
  var doors = get_tree().get_nodes_in_group(Constants.GROUPS.DOORS)
  var structures = get_tree().get_nodes_in_group(Constants.GROUPS.STRUCTURES)

  var saved_creatures = []
  for creature in creatures:
    saved_creatures.append({
      "node_name": creature.get_filename(),
      "hitpoints": creature.mortality.hitpoints,
      "x": level.world_to_map(creature.position).x,
      "y": level.world_to_map(creature.position).y
    })
  
  var saved_doors = []
  for door in doors:
    saved_doors.append({
      "node_name": door.get_filename(),
      "closed": door.closed,
      "x": level.world_to_map(door.position).x,
      "y": level.world_to_map(door.position).y
    })
  
  var saved_structures = []
  for structure in structures:
    saved_structures.append({
      "node_name": structure.get_filename(),
      "x": level.world_to_map(structure.position).x,
      "y": level.world_to_map(structure.position).y
    })
  
  return {
    "creatures": saved_creatures,
    "doors": saved_doors,
    "structures": saved_structures
  }

func load_game():
  var game_save = File.new()
  var open_error = game_save.open(game_save_path, File.READ)
  if open_error != OK:
    print("No saved game to open.")
    return
  # Before we deal with the current level, load the Game singleton and its 
  while game_save.get_position() < game_save.get_len():
    # Get the saved dictionary from the next line in the save file
    var node = parse_json(game_save.get_line())
    if "hitpoints" in node:
      Game.player_carry_over = node
    elif "current_floor" in node:
      Game.highest_level = node.highest_level
      Game.current_floor = node.current_floor
  load_level(Game.current_floor)

func load_level(index: int):
  var level_load = File.new()
  var open_error = level_load.open("user://level%d.avosave" % [index], File.READ)
  if open_error != OK:
    print("level not found.")
    return
  var level_node = parse_json(level_load.get_line())
  Game.loading_existing_tilemap = true
  Game.existing_level = level_node

