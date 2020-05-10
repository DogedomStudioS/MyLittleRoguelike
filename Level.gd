extends Node2D

const WIDTH = 34
const HEIGHT = 20

# One-dimensional array of tiles. [x, y] -> tiles[(y * WIDTH) + x]
var tiles = []

onready var floor_layer: TileMap = $Floor
onready var obstacle_layer: TileMap = $Obstacles

func clear_map():
	for x in range(WIDTH):
		for y in range(HEIGHT): 
			floor_layer.set_cell(x, y, 0)
		
func _ready():
	clear_map()

# generate rooms
# Find path and generate cooridors
# convert to tilemap
