extends Node2D
## Main Game Controller

# Preloaded scenes
var cannon_scene: PackedScene = preload("res://scenes/cannons/cannon.tscn")
var enemy_scene: PackedScene = preload("res://scenes/enemies/enemy.tscn")

# Grid tracking
var grid: Array[Array] = []  # 2D array to track cannon placement
var cannons: Array[Node2D] = []
var enemies: Array[Node2D] = []

# Wave management
var wave_timer: float = 0.0
var spawn_timer: float = 0.0
var enemies_to_spawn: int = 0
var wave_in_progress: bool = false
const WAVE_DELAY: float = 5.0
const SPAWN_INTERVAL: float = 1.0

# References
@onready var grid_layer: Node2D = $GridLayer
@onready var cannon_layer: Node2D = $CannonLayer
@onready var enemy_layer: Node2D = $EnemyLayer
@onready var bullet_layer: Node2D = $BulletLayer
@onready var ui_layer: CanvasLayer = $UILayer
@onready var hud: Control = $UILayer/HUD


func _ready() -> void:
	_init_grid()
	_draw_grid()
	GameData.reset_game()
	_connect_signals()


func _connect_signals() -> void:
	GameData.game_over.connect(_on_game_over)


func _init_grid() -> void:
	grid.clear()
	for x in range(GameData.GRID_COLS):
		var column: Array[Node2D] = []
		column.resize(GameData.GRID_ROWS)
		grid.append(column)


func _draw_grid() -> void:
	# Draw checkerboard pattern
	for x in range(GameData.GRID_COLS):
		for y in range(GameData.GRID_ROWS):
			var cell := ColorRect.new()
			cell.size = Vector2(GameData.CELL_WIDTH, GameData.CELL_HEIGHT)
			cell.position = Vector2(x * GameData.CELL_WIDTH, y * GameData.CELL_HEIGHT)

			# Alternating colors for checkerboard
			if (x + y) % 2 == 0:
				cell.color = Color(0.3, 0.35, 0.3, 1.0)  # Dark green-gray
			else:
				cell.color = Color(0.35, 0.4, 0.35, 1.0)  # Lighter green-gray

			grid_layer.add_child(cell)


func _process(delta: float) -> void:
	if GameData.is_game_over or GameData.is_paused:
		return

	_handle_waves(delta)
	_cleanup_dead_enemies()


func _handle_waves(delta: float) -> void:
	if wave_in_progress:
		_spawn_enemies(delta)
	else:
		wave_timer += delta
		if wave_timer >= WAVE_DELAY:
			_start_wave()


func _start_wave() -> void:
	GameData.next_wave()
	wave_timer = 0.0
	spawn_timer = 0.0
	enemies_to_spawn = 5 + GameData.wave * 2
	wave_in_progress = true


func _spawn_enemies(delta: float) -> void:
	if enemies_to_spawn <= 0:
		if enemies.size() == 0:
			wave_in_progress = false
		return

	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		_spawn_enemy()
		enemies_to_spawn -= 1


func _spawn_enemy() -> void:
	var enemy := enemy_scene.instantiate()

	# Determine enemy type based on wave
	var enemy_type: int = _get_enemy_type_for_wave()
	enemy.init(enemy_type, bullet_layer)

	# Spawn at random position on the right side
	var spawn_y := randf_range(50, GameData.VIEWPORT_HEIGHT - 50)
	enemy.position = Vector2(GameData.VIEWPORT_WIDTH + 50, spawn_y)

	# Set target to left side
	enemy.target_x = -50.0

	enemy_layer.add_child(enemy)
	enemies.append(enemy)
	enemy.died.connect(_on_enemy_died.bind(enemy))
	enemy.reached_end.connect(_on_enemy_reached_end.bind(enemy))


func _get_enemy_type_for_wave() -> int:
	var roll := randf()

	if GameData.wave >= 10 and roll < 0.1:
		return GameData.EnemyType.MONSTER_SOLDIER
	elif GameData.wave >= 7 and roll < 0.2:
		return GameData.EnemyType.SMART_SOLDIER
	elif GameData.wave >= 5 and roll < 0.3:
		return GameData.EnemyType.FAST_SOLDIER
	elif GameData.wave >= 3 and roll < 0.4:
		return GameData.EnemyType.BIG_SOLDIER
	else:
		return GameData.EnemyType.SOLDIER


func _cleanup_dead_enemies() -> void:
	enemies = enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())


func _on_enemy_died(enemy: Node2D) -> void:
	if is_instance_valid(enemy):
		var stats: Dictionary = GameData.ENEMY_STATS[enemy.enemy_type]
		GameData.add_money(stats.reward)
		GameData.add_score(stats.reward * 10)


func _on_enemy_reached_end(enemy: Node2D) -> void:
	if is_instance_valid(enemy):
		var stats: Dictionary = GameData.ENEMY_STATS[enemy.enemy_type]
		GameData.lose_life(int(stats.damage / 10))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)


func _handle_click(click_pos: Vector2) -> void:
	if GameData.is_game_over:
		return

	var grid_pos := GameData.world_to_grid(click_pos)

	if not GameData.is_valid_grid_pos(grid_pos):
		return

	# Check if cell is empty
	if grid[grid_pos.x][grid_pos.y] != null:
		return

	# Check if we can afford the cannon
	var cannon_stats: Dictionary = GameData.CANNON_STATS[GameData.selected_cannon_type]
	if not GameData.spend_money(cannon_stats.cost):
		return

	# Place cannon
	_place_cannon(grid_pos)


func _place_cannon(grid_pos: Vector2i) -> void:
	var cannon := cannon_scene.instantiate()
	cannon.init(GameData.selected_cannon_type, bullet_layer)
	cannon.position = GameData.grid_to_world(grid_pos)
	cannon.grid_position = grid_pos

	cannon_layer.add_child(cannon)
	cannons.append(cannon)
	grid[grid_pos.x][grid_pos.y] = cannon

	cannon.tree_exited.connect(_on_cannon_removed.bind(grid_pos))


func _on_cannon_removed(grid_pos: Vector2i) -> void:
	grid[grid_pos.x][grid_pos.y] = null


func _on_game_over() -> void:
	# Show game over UI
	if hud.has_method("show_game_over"):
		hud.show_game_over()


func get_enemies_in_range(from_pos: Vector2, attack_range: float) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			if from_pos.distance_to(enemy.position) <= attack_range:
				result.append(enemy)
	return result


func get_closest_enemy(from_pos: Vector2, attack_range: float) -> Node2D:
	var closest: Node2D = null
	var closest_dist: float = attack_range + 1.0

	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			var dist := from_pos.distance_to(enemy.position)
			if dist <= attack_range and dist < closest_dist:
				closest = enemy
				closest_dist = dist

	return closest
