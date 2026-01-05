extends Node
## A* Pathfinding System for Enemy Navigation

# Grid representation for pathfinding
var grid_obstacles: Array = []  # 2D array of booleans (true = blocked)
var grid_cols: int = 8
var grid_rows: int = 5

# Pathfinding cache
var cached_path: Array[Vector2i] = []
var path_dirty: bool = true


func _ready() -> void:
	_init_grid()


func _init_grid() -> void:
	grid_cols = GameData.GRID_COLS
	grid_rows = GameData.GRID_ROWS
	grid_obstacles.clear()
	for x in range(grid_cols):
		var column: Array = []
		for y in range(grid_rows):
			column.append(false)
		grid_obstacles.append(column)


func set_obstacle(grid_pos: Vector2i, is_blocked: bool) -> void:
	if _is_valid_pos(grid_pos):
		grid_obstacles[grid_pos.x][grid_pos.y] = is_blocked
		path_dirty = true


func is_obstacle(grid_pos: Vector2i) -> bool:
	if not _is_valid_pos(grid_pos):
		return true
	return grid_obstacles[grid_pos.x][grid_pos.y]


func _is_valid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_cols and pos.y >= 0 and pos.y < grid_rows


## Check if placing a cannon at this position would block all paths
func would_block_all_paths(grid_pos: Vector2i) -> bool:
	if not _is_valid_pos(grid_pos):
		return true

	# Temporarily set as obstacle
	var was_blocked: bool = grid_obstacles[grid_pos.x][grid_pos.y]
	grid_obstacles[grid_pos.x][grid_pos.y] = true

	# Check if any path exists from right edge to left edge
	var path_exists := _check_any_path_exists()

	# Restore original state
	grid_obstacles[grid_pos.x][grid_pos.y] = was_blocked

	return not path_exists


func _check_any_path_exists() -> bool:
	# Check from multiple spawn points on right side to exit on left
	for y in range(grid_rows):
		var start := Vector2i(grid_cols - 1, y)
		var end := Vector2i(-1, y)  # Target is off-grid left

		# Use simplified path check - just need to reach x = 0
		if _can_reach_left_edge(start):
			return true

	return false


func _can_reach_left_edge(start: Vector2i) -> bool:
	# BFS to check if we can reach x = 0 from start
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	visited[start] = true

	while queue.size() > 0:
		var current: Vector2i = queue.pop_front()

		# Reached left edge
		if current.x == 0:
			return true

		# Check all 4 directions (prioritize left movement)
		var directions: Array[Vector2i] = [
			Vector2i(-1, 0),  # Left
			Vector2i(0, -1),  # Up
			Vector2i(0, 1),   # Down
			Vector2i(1, 0)    # Right (backtrack if needed)
		]

		for dir in directions:
			var next: Vector2i = current + dir
			if _is_valid_pos(next) and not visited.has(next) and not grid_obstacles[next.x][next.y]:
				visited[next] = true
				queue.append(next)

	return false


## Find path from start to target using A*
func find_path(start: Vector2i, target_x: int) -> Array[Vector2i]:
	var path: Array[Vector2i] = []

	# Start position validation
	if not _is_valid_pos(start):
		return path

	# A* implementation
	var open_set: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start: 0.0}
	var f_score: Dictionary = {start: _heuristic(start, target_x)}

	while open_set.size() > 0:
		# Get node with lowest f_score
		var current: Vector2i = _get_lowest_f(open_set, f_score)

		# Reached target (left side of grid or beyond)
		if current.x <= target_x:
			return _reconstruct_path(came_from, current)

		open_set.erase(current)

		# Check neighbors
		var neighbors: Array[Vector2i] = _get_neighbors(current)
		for neighbor in neighbors:
			var tentative_g: float = g_score[current] + 1.0

			if not g_score.has(neighbor) or tentative_g < g_score[neighbor]:
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _heuristic(neighbor, target_x)

				if not open_set.has(neighbor):
					open_set.append(neighbor)

	# No path found - return simple left movement
	return _get_simple_path(start, target_x)


func _heuristic(pos: Vector2i, target_x: int) -> float:
	# Manhattan distance to left edge
	return float(pos.x - target_x)


func _get_lowest_f(open_set: Array[Vector2i], f_score: Dictionary) -> Vector2i:
	var lowest: Vector2i = open_set[0]
	var lowest_score: float = f_score.get(lowest, INF)

	for pos in open_set:
		var score: float = f_score.get(pos, INF)
		if score < lowest_score:
			lowest = pos
			lowest_score = score

	return lowest


func _get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions: Array[Vector2i] = [
		Vector2i(-1, 0),  # Left
		Vector2i(1, 0),   # Right
		Vector2i(0, -1),  # Up
		Vector2i(0, 1)    # Down
	]

	for dir in directions:
		var next: Vector2i = pos + dir
		if _is_valid_pos(next) and not grid_obstacles[next.x][next.y]:
			neighbors.append(next)

	# Allow moving off left edge
	if pos.x == 0:
		neighbors.append(Vector2i(-1, pos.y))

	return neighbors


func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.insert(0, current)
	return path


func _get_simple_path(start: Vector2i, target_x: int) -> Array[Vector2i]:
	# Fallback: just go left
	var path: Array[Vector2i] = []
	var current := start
	while current.x > target_x:
		current = Vector2i(current.x - 1, current.y)
		path.append(current)
	return path


## Get world position for a grid cell center
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return GameData.grid_to_world(grid_pos)


## Convert world position to grid position
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return GameData.world_to_grid(world_pos)


## Clear all obstacles (for level reset)
func clear_obstacles() -> void:
	for x in range(grid_cols):
		for y in range(grid_rows):
			grid_obstacles[x][y] = false
	path_dirty = true
