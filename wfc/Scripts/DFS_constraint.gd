class_name DFSGridConstraint
extends RefCounted

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

func generate(size: Vector2i, seed_value: int = 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()

	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value

	var width := size.x
	var height := size.y

	if width <= 0 or height <= 0:
		return {}

	var visited: Dictionary = {}
	var required: Dictionary = {}
	var flags: Dictionary = {}
	var path: Array[Vector2i] = []

	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			required[pos] = {
				"up": false,
				"down": false,
				"left": false,
				"right": false,
			}

	var start := Vector2i(
		rng.randi_range(0, width - 1),
		rng.randi_range(0, height - 1)
	)

	var stack: Array[Vector2i] = [start]
	visited[start] = true
	flags[start] = true
	path.append(start)

	while stack.size() > 0:
		var current: Vector2i = stack[stack.size() - 1]
		var unvisited_neighbors := _get_unvisited_neighbors(current, width, height, visited, rng)

		if unvisited_neighbors.is_empty():
			stack.pop_back()
			continue

		var chosen: Dictionary = unvisited_neighbors[0]
		var dir_name: String = chosen["dir"]
		var next_pos: Vector2i = chosen["pos"]

		required[current][dir_name] = true
		required[next_pos][OPPOSITE[dir_name]] = true

		visited[next_pos] = true
		flags[next_pos] = true
		path.append(next_pos)
		stack.append(next_pos)

	var end := path[path.size() - 1]

	return {
		"required": required,
		"flags": flags,
		"path": path,
		"start": start,
		"end": end,
	}


func _get_unvisited_neighbors(
	pos: Vector2i,
	width: int,
	height: int,
	visited: Dictionary,
	rng: RandomNumberGenerator
) -> Array:
	var result: Array = []

	for dir_name in DIRS.keys():
		var next_pos: Vector2i = pos + DIRS[dir_name]

		if next_pos.x < 0:
			continue
		if next_pos.y < 0:
			continue
		if next_pos.x >= width:
			continue
		if next_pos.y >= height:
			continue
		if visited.has(next_pos):
			continue

		result.append({
			"dir": dir_name,
			"pos": next_pos,
		})

	_shuffle_array(result, rng)
	return result


func _shuffle_array(array: Array, rng: RandomNumberGenerator) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp
