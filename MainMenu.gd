extends Control

func _ready():
	pass

func _on_Quit_pressed():
	get_tree().quit()


func _on_New_Game_pressed():
	get_tree().change_scene("res://level/World.tscn")
