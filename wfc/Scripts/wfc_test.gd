extends Node2D

@export var map_layer: TileMapLayer
@export var WIDTH := 10
@export var HEIGHT := 10

var restart_count := 0

const ALL_TILES := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]

const TILE_TO_ATLAS := {
	0: {"source_id": 0, "atlas": Vector2i(0,0), "alt": 0},
	1: {"source_id": 0, "atlas": Vector2i(1,0), "alt": 0},
	2: {"source_id": 0, "atlas": Vector2i(2,0), "alt": 0},
	3: {"source_id": 0, "atlas": Vector2i(3,0), "alt": 0},
	4: {"source_id": 0, "atlas": Vector2i(4,0), "alt": 0},
	5: {"source_id": 0, "atlas": Vector2i(5,0), "alt": 0},
	6: {"source_id": 0, "atlas": Vector2i(6,0), "alt": 0},
	7: {"source_id": 0, "atlas": Vector2i(0,1), "alt": 0},
	8: {"source_id": 0, "atlas": Vector2i(1,1), "alt": 0},
	9: {"source_id": 0, "atlas": Vector2i(4,1), "alt": 0},
	10: {"source_id": 0, "atlas": Vector2i(5,1), "alt": 0},
	11: {"source_id": 0, "atlas": Vector2i(6,1), "alt": 0},
}

const DIRS := {
	"up": Vector2i(0, -1),
	"down": Vector2i(0, 1),
	"left": Vector2i(-1, 0),
	"right": Vector2i(1, 0),
}

const OPPOSITE := {
	"up": "down",
	"down": "up",
	"right": "left",
	"left": "right",
}

var open := {
	0: {"up": false, "down": true, "right": true, "left": false},
	1: {"up": false, "down": true, "right": false, "left": true},
	2: {"up": false, "down": false, "right": true, "left": false},
	3: {"up": false, "down": false, "right": false, "left": true},
	4: {"up": false, "down": true, "right": false, "left": false},
	5: {"up": false, "down": true, "right": true, "left": true},
	6: {"up": true, "down": false, "right": true, "left": true},
	7: {"up": true, "down": false, "right": true, "left": false},
	8: {"up": true, "down": false, "right": false, "left": true},
	9: {"up": true, "down": false, "right": false, "left": false},
	10: {"up": true, "down": true, "right": false, "left": true},
	11: {"up": true, "down": true, "right": true, "left": false},
}

var rng := RandomNumberGenerator.new()
var cells := {}

func _ready() -> void:
	print("ready")
	rng.randomize()
	generate()

func generate() -> void:
	initialize_cells()
	
	while true:
		var pos = find_lowest_entropy_cell()
		if pos == null:
			break
		collapse_cell(pos)
		
		var ok = propagate(pos)
		if not ok:
			restart_count += 1
			print("Contradiction hit. Restart Count:", restart_count)
			generate()
			return
	draw_result()
	
func initialize_cells() -> void:
	cells.clear()
	for y in range(HEIGHT):
		for x in range(WIDTH):
			cells[Vector2i(x,y)] = ALL_TILES.duplicate()

func find_lowest_entropy_cell():
	var best_pos = null
	var best_size = 999999
	
	for pos in cells.keys():
		var options: Array = cells[pos]
		var size = options.size()
		if size > 1 and size < best_size:
			best_size = size
			best_pos = pos
	
	return best_pos
	
func collapse_cell(pos: Vector2i) -> void:
	var options: Array = cells[pos]
	var chosen = options[rng.randi_range(0, options.size() - 1)]
	cells[pos] = [chosen]
	
func propagate(start_pos: Vector2i) -> bool:
	var queue: Array[Vector2i] = [start_pos]
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var current_options: Array = cells[current]
		
		for dir_name in DIRS.keys():
			var neighbour = current + DIRS[dir_name]
			
			if not cells.has(neighbour):
				continue
			
			var neighbour_options: Array = cells[neighbour]
			var new_neighbour_options: Array = []
			
			for n_tile in neighbour_options:
				var valid := false
				
				for c_tile in current_options:
					if is_compatible(open[c_tile], dir_name, open[n_tile]):
						valid = true
						break
				
				if valid:
					new_neighbour_options.append(n_tile)
			
			if new_neighbour_options.size() == 0:
				return false
			
			if new_neighbour_options.size() < neighbour_options.size():
				cells[neighbour] = new_neighbour_options
				queue.append(neighbour)
				
	return true
	
func opposite_dir(dir: String) -> String:
	match dir:
		"up": return "down"
		"right": return "left"
		"down": return "up"
		"left": return "right"
		_: return ""

func get_socket(tile_def: Dictionary, dir: String) -> bool:
	return tile_def[dir]

func is_compatible(a: Dictionary, dir_from_a: String, b: Dictionary) -> bool:
	var a_socket = get_socket(a, dir_from_a)
	var b_socket = get_socket(b, opposite_dir(dir_from_a))
	return a_socket == b_socket
	
func draw_result() -> void:
	map_layer.clear()

	for y in range(HEIGHT):
		for x in range(WIDTH):
			var pos := Vector2i(x, y)
			var tile_id: int = cells[pos][0]
			var tile_info = TILE_TO_ATLAS[tile_id]

			map_layer.set_cell(
				pos,
				tile_info["source_id"],
				tile_info["atlas"],
				tile_info["alt"]
			)
