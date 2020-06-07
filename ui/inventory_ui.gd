extends Control

onready var weapons_list: ItemList = $OuterContainer/InnerContainer/Left/MarginContainer/WeaponsList
onready var items_list: ItemList = $OuterContainer/InnerContainer/Right/MarginContainer/ItemsList
var host

func show_inventory(new_host):
  host = new_host
  var weapons = host.inventory.weapons
  var items = host.inventory.items
  weapons_list.clear()
  items_list.clear()
  var weapons_index = 0
  for weapon in weapons:
    weapons_list.add_item(weapon.label, weapon.icon)
    if host.attack.weapon == weapon:
      weapons_list.select(weapons_index)
    weapons_index += 1
  for item in items:
    items_list.add_item(item.label, item.icon)

func _weapon_selected(index):
  if "attack" in host:
    host.attack.arm_weapon(host.inventory.weapons[index])


func _on_WeaponsList_item_selected(index):
  if host and "attack" in host:
    host.attack.arm_weapon(host.inventory.weapons[index], true)


func _on_ItemsList_item_selected(index):
  pass # Replace with function body.


func _on_Button_pressed():
  if host and "attack" in host:
    weapons_list.unselect_all()
    host.attack.arm_weapon(null, true)
