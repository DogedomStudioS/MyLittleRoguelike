extends Control

onready var weapons_list: ItemList = $OuterContainer/InnerContainer/Left/MarginContainer/WeaponsList
onready var items_list: ItemList = $OuterContainer/InnerContainer/Right/MarginContainer/ItemsList
var host

func show_inventory(new_host):
  host = new_host
  refresh_inventory_lists()

func _weapon_selected(index):
  if "attack" in host:
    host.attack.arm_weapon(host.inventory.weapons[index])


func _on_WeaponsList_item_selected(index):
  if host and "attack" in host:
    host.attack.arm_weapon(host.inventory.weapons[index], true)


func _on_ItemsList_item_selected(index):
  if host:
    var item = host.inventory.items[index]
    match item.type:
      Constants.ITEM_TYPE.consumable:
        if "on_use" in item:
          item.on_use.call_func(host, item)
          host.inventory.remove_item(index)
          refresh_inventory_lists()

func _on_ItemsList_item_dropped(index):
  if host:
    var item = host.inventory.items[index]
    if "drop" in item:
      host.inventory.drop(item)
      host.inventory.remove_item(index)
      refresh_inventory_lists()

# TODO: this needs to be a signal of some sort
func refresh_inventory_lists():
  var weapons = host.inventory.weapons
  var items = host.inventory.items
  weapons_list.clear()
  items_list.clear()
  var weapons_index = 0
  for weapon in weapons:
    var icon = weapon.icon
    if typeof(icon) == TYPE_STRING:
      icon = load(icon)
    weapons_list.add_item(weapon.label, icon)
    if host.attack.weapon == weapon:
      weapons_list.select(weapons_index)
  weapons_index += 1
  for item in items:
    var icon = item.icon
    if typeof(icon) == TYPE_STRING:
      icon = load(icon)
    items_list.add_item(item.label, icon)

func _on_Button_pressed():
  if host and "attack" in host:
    weapons_list.unselect_all()
    host.attack.arm_weapon(null, true)


func _on_ItemsList_item_rmb_selected(index, _at_position):
  if host:
    var item = host.inventory.items[index]
    if "drop" in item:
      host.inventory.drop(item)
      host.inventory.remove_item(index)
      refresh_inventory_lists()


func _on_ItemsList_item_activated(index):
  if host:
    var item = host.inventory.items[index]
    match int(item.type):
      Constants.ITEM_TYPE.consumable:
        if "on_use" in item:
          #item.on_use.call_func(host, item)
          Items.call(item.on_use, host, item)
          host.inventory.remove_item(index)
          refresh_inventory_lists()
