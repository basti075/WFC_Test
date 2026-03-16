extends Node2D

@export var map_layer: TileMapLayer
@export var WIDTH := 10
@export var HEIGHT := 10

@export var step_count := 20
@export var min_length := 10

var walk_required: Dictionary = {}
var walk_flags: Dictionary = {}
var walk_path: Array[Vector2i] = []
var exact_path := false

var start_pos: Vector2i = Vector2i.ZERO
var end_pos: Vector2i = Vector2i.ZERO

var restart_count := 0

const ALL_TILES := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

const ALT_NORMAL := 0
const ALT_PATH := 1
const ALT_START := 2
const ALT_END := 3

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
	#12: {"source_id": 0, "atlas": Vector2i(0,2), "alt": 0},
	#13: {"source_id": 0, "atlas": Vector2i(1,2), "alt": 0},
	#14: {"source_id": 0, "atlas": Vector2i(2,2), "alt": 0},
	#15: {"source_id": 0, "atlas": Vector2i(3,2), "alt": 0},
	#16: {"source_id": 0, "atlas": Vector2i(4,2), "alt": 0},
	#17: {"source_id": 0, "atlas": Vector2i(5,2), "alt": 0},
	#18: {"source_id": 0, "atlas": Vector2i(6,2), "alt": 0},
	#19: {"source_id": 0, "atlas": Vector2i(0,3), "alt": 0},
	#20: {"source_id": 0, "atlas": Vector2i(1,3), "alt": 0},
	#21: {"source_id": 0, "atlas": Vector2i(4,3), "alt": 0},
	#22: {"source_id": 0, "atlas": Vector2i(5,3), "alt": 0},
	#23: {"source_id": 0, "atlas": Vector2i(6,3), "alt": 0},
	12: {"source_id": 0, "atlas": Vector2i(7,0), "alt": 0},
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
	0: {"up": "x", "down": "a", "right": "a", "left": "x"},
	1: {"up": "x", "down": "a", "right": "x", "left": "a"},
	2: {"up": "x", "down": "x", "right": "b", "left": "x"},
	3: {"up": "x", "down": "x", "right": "x", "left": "b"},
	4: {"up": "x", "down": "b", "right": "x", "left": "x"},
	5: {"up": "x", "down": "a", "right": "a", "left": "a"},
	6: {"up": "a", "down": "x", "right": "a", "left": "a"},
	7: {"up": "a", "down": "x", "right": "a", "left": "x"},
	8: {"up": "a", "down": "x", "right": "x", "left": "a"},
	9: {"up": "b", "down": "x", "right": "x", "left": "x"},
	10: {"up": "a", "down": "a", "right": "x", "left": "a"},
	11: {"up": "a", "down": "a", "right": "a", "left": "x"},
	#12: {"up": "x", "down": "a", "right": "a", "left": "x"},
	#13: {"up": "x", "down": "a", "right": "x", "left": "a"},
	#14: {"up": "x", "down": "x", "right": "b", "left": "x"},
	#15: {"up": "x", "down": "x", "right": "x", "left": "b"},
	#16: {"up": "x", "down": "b", "right": "x", "left": "x"},
	#17: {"up": "x", "down": "a", "right": "a", "left": "a"},
	#18: {"up": "a", "down": "x", "right": "a", "left": "a"},
	#19: {"up": "a", "down": "x", "right": "a", "left": "x"},
	#20: {"up": "a", "down": "x", "right": "x", "left": "a"},
	#21: {"up": "b", "down": "x", "right": "x", "left": "x"},
	#22: {"up": "a", "down": "a", "right": "x", "left": "a"},
	#23: {"up": "a", "down": "a", "right": "a", "left": "x"},
	12: {"up": "a", "down": "a", "right": "a", "left": "a"},
}

const SOCKET_OK: Dictionary = {
	"a": ["a", "b"],
	"b": ["a"],
	"x": ["x"],
}

var rng := RandomNumberGenerator.new()
var cells := {}

func _ready() -> void:
	restart_count = 0
	print("ready")
	rng.randomize()
	
	var walker := RandomWalkConstraint.new()
	var result : Dictionary = walker.generate(Vector2i(WIDTH, HEIGHT), step_count, rng.randi(), min_length, 64)
	
	if result.is_empty():
		push_error("random walk failed")
		return
		
	walk_required = result.get("required", {})
	walk_flags = result.get("flags", {})
	walk_path = result.get("path", [])
	start_pos = result.get("start", Vector2i.ZERO)
	end_pos = result.get("end", Vector2i.ZERO)
	
	generate()
	
func _input(event):
	if event.is_action_pressed("Refresh"):
		print("refresh")
		restart_count = 0
		rng.randomize()
	
		var walker := RandomWalkConstraint.new()
		var result : Dictionary = walker.generate(Vector2i(WIDTH, HEIGHT), step_count, rng.randi(), min_length, 64)
	
		if result.is_empty():
			push_error("random walk failed")
			return
		
		walk_required = result.get("required", {})
		walk_flags = result.get("flags", {})
		walk_path = result.get("path", [])
		start_pos = result.get("start", Vector2i.ZERO)
		end_pos = result.get("end", Vector2i.ZERO)

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
			var pos := Vector2i(x, y)
			var options: Array = []
			
			for tile_id in range(open.size()):
				if not is_tile_allowed_at_position(tile_id, pos):
					continue
					
				if walk_required.has(pos):
					var required_dirs: Dictionary = walk_required[pos]
					if not tile_matches_walk_constraint(tile_id, required_dirs, exact_path):
						continue
						
				options.append(tile_id)
					
			cells[pos] = options

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

func get_socket(tile_def: Dictionary, dir: String) -> String:
	return tile_def[dir]

func is_compatible(a: Dictionary, dir_from_a: String, b: Dictionary) -> bool:
	var a_socket = get_socket(a, dir_from_a)
	var b_socket = get_socket(b, opposite_dir(dir_from_a))
	return b_socket in SOCKET_OK.get(a_socket, [])
	
func draw_result() -> void:
	map_layer.clear()

	for y in range(HEIGHT):
		for x in range(WIDTH):
			var pos := Vector2i(x, y)
			var tile_id: int = cells[pos][0]
			var tile_info = TILE_TO_ATLAS[tile_id]
			
			var alt := ALT_NORMAL
			
			if pos == start_pos:
				alt = ALT_START
			elif pos == end_pos:
				alt = ALT_END
			elif walk_flags.has(pos):
				alt = ALT_PATH
				

			map_layer.set_cell(
				pos,
				tile_info["source_id"],
				tile_info["atlas"], 
				alt
			)
			

func is_tile_allowed_at_position(tile_id: int, pos: Vector2i) -> bool:
	var s = open[tile_id]

	if pos.y == 0 and s["up"] != "x":
		return false
	if pos.y == HEIGHT - 1 and s["down"] != "x":
		return false
	if pos.x == 0 and s["left"] != "x":
		return false
	if pos.x == WIDTH - 1 and s["right"] != "x":
		return false

	return true


func tile_matches_walk_constraint(tile_id: int, required_dirs: Dictionary, exact_match: bool = false) -> bool:
	var sockets: Dictionary = open[tile_id]

	for dir_name in DIRS.keys():
		var must_be_open: bool = required_dirs.get(dir_name, false)
		var is_open: bool = sockets[dir_name] == "a"

		if must_be_open and not is_open:
			return false

		if exact_match and (must_be_open != is_open):
			return false

	return true
