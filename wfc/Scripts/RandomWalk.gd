# RandomWalkConstraint.gd
# Godot 4.x

class_name RandomWalkConstraint
extends RefCounted

const DIRS := [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.UP,
]

const DIR_NAME := {
	Vector2i.RIGHT: "right",
	Vector2i.LEFT: "left",
	Vector2i.DOWN: "down",
	Vector2i.UP: "up",
}

const OPPOSITE := {
	"right": "left",
	"left": "right",
	"down": "up",
	"up": "down",
}

func generate(
	grid_size: Vector2i,
	step_count: int,
	seed: int,
	min_length: int,
	max_restarts: int
) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	for _attempt in range(max_restarts):
		var start := Vector2i(
			rng.randi_range(0, grid_size.x - 1),
			rng.randi_range(0, grid_size.y - 1)
		)

		var path := _walk_once(start, grid_size, step_count, rng)

		if path.size() < min_length:
			continue
		
		var end: Vector2i = path[path.size() - 1]
		

		var start_left := start.x < grid_size.x / 2
		var end_left := end.x < grid_size.x / 2

		if start_left == end_left:
			continue

		if abs(start.x - end.x) + abs(start.y - end.y) < 6:
			continue
		
		return {
				"start": start,
				"end": end,
				"path": path,
				"flags": _build_flags(path),
				"required": build_required_connections(path),
			}

	return {}


func _walk_once(
	start: Vector2i,
	grid_size: Vector2i,
	step_count: int,
	rng: RandomNumberGenerator
) -> Array[Vector2i]:
	var path: Array[Vector2i] = [start]
	var visited := {start: true}

	for _i in range(step_count - 1):
		var current: Vector2i = path[path.size() - 1]
		var options: Array[Vector2i] = []

		for dir: Vector2i in DIRS:
			var next := current + dir
			if not _in_bounds(next, grid_size):
				continue
			if visited.has(next):
				continue
			options.append(next)

		if options.is_empty():
			break

		var chosen := options[rng.randi_range(0, options.size() - 1)]
		path.append(chosen)
		visited[chosen] = true

	return path


func _build_flags(path: Array[Vector2i]) -> Dictionary:
	var flags := {}

	if path.is_empty():
		return flags

	flags[path[0]] = "start"

	for i in range(1, path.size() - 1):
		flags[path[i]] = "path"

	flags[path[path.size() - 1]] = "end"
	return flags


func build_required_connections(path: Array[Vector2i]) -> Dictionary:
	# Returns:
	# {
	#   Vector2i(4, 7): {"N": false, "E": true, "S": false, "W": false},
	#   Vector2i(5, 7): {"N": false, "E": true, "S": false, "W": true},
	#   ...
	# }
	var required := {}

	for cell in path:
		required[cell] = {
			"up": false,
			"down": false,
			"left": false,
			"right": false,
		}

	for i in range(path.size() - 1):
		var a: Vector2i = path[i]
		var b: Vector2i = path[i + 1]
		var delta := b - a
		var dir: String = DIR_NAME.get(delta, "")
		var opp: String = OPPOSITE.get(dir, "")

		required[a][dir] = true
		required[b][opp] = true

	return required


func tile_satisfies_constraint(
	tile_connections: Dictionary,
	required_connections: Dictionary,
	exact_match: bool = false
) -> bool:
	# tile_connections example:
	# {"N": false, "E": true, "S": true, "W": false}
	#
	# exact_match = false:
	#   tile may have extra exits beyond the required path
	# exact_match = true:
	#   tile must match exactly
	for key in ["up", "left", "down", "right"]:
		if required_connections[key] and not tile_connections[key]:
			return false

		if exact_match and tile_connections[key] != required_connections[key]:
			return false

	return true


func debug_paint_path(
	layer: TileMapLayer,
	path: Array[Vector2i],
	source_id: int,
	atlas_coords: Vector2i,
	alternative_tile: int = 0
) -> void:
	for cell in path:
		layer.set_cell(cell, source_id, atlas_coords, alternative_tile)


func _in_bounds(cell: Vector2i, grid_size: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.y >= 0
		and cell.x < grid_size.x
		and cell.y < grid_size.y
	)
