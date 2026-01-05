extends Node2D
## Main Game Controller

# Preloaded scenes
var cannon_scene: PackedScene = preload("res://scenes/cannons/cannon.tscn")
var enemy_scene: PackedScene = preload("res://scenes/enemies/enemy.tscn")

# Grid tracking
var grid: Array[Array] = []
var cannons: Array[Node2D] = []
var enemies: Array[Node2D] = []

# Wave management
var wave_timer: float = 0.0
var spawn_timer: float = 0.0
var enemies_to_spawn: int = 0
var wave_in_progress: bool = false
const WAVE_DELAY: float = 4.0
const SPAWN_INTERVAL: float = 0.8

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
	GameData.victory.connect(_on_victory)


func _init_grid() -> void:
	grid.clear()
	for x in range(GameData.GRID_COLS):
		var column: Array[Node2D] = []
		column.resize(GameData.GRID_ROWS)
		grid.append(column)

	# Reset pathfinding obstacles
	Pathfinding.clear_obstacles()


func _draw_grid() -> void:
	for x in range(GameData.GRID_COLS):
		for y in range(GameData.GRID_ROWS):
			var cell := ColorRect.new()
			cell.size = Vector2(GameData.CELL_WIDTH, GameData.CELL_HEIGHT)
			cell.position = Vector2(x * GameData.CELL_WIDTH, y * GameData.CELL_HEIGHT)

			# Dark minimalist grid on black
			if (x + y) % 2 == 0:
				cell.color = Color(0.08, 0.10, 0.08, 1.0)
			else:
				cell.color = Color(0.10, 0.12, 0.10, 1.0)

			grid_layer.add_child(cell)


func _process(delta: float) -> void:
	if GameData.is_game_over or GameData.is_paused or GameData.is_victory:
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

	# Enemy count scales with wave and difficulty
	var base_count := 4 + GameData.wave * 2
	enemies_to_spawn = int(base_count * GameData.get_enemy_count_multiplier())
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
	var enemy_type: int = _get_enemy_type_for_wave()
	enemy.init(enemy_type, bullet_layer, self)

	var spawn_y := randf_range(60, GameData.VIEWPORT_HEIGHT - 60)
	enemy.position = Vector2(GameData.VIEWPORT_WIDTH + 50, spawn_y)
	enemy.target_x = -50.0

	enemy_layer.add_child(enemy)
	enemies.append(enemy)
	enemy.died.connect(_on_enemy_died.bind(enemy))
	enemy.reached_end.connect(_on_enemy_reached_end.bind(enemy))


func _get_enemy_type_for_wave() -> int:
	var roll := randf()
	var wave := GameData.wave

	# Progressive enemy unlock
	if wave >= 12 and roll < 0.08:
		return GameData.EnemyType.RESISTANT
	elif wave >= 10 and roll < 0.12:
		return GameData.EnemyType.FLYING
	elif wave >= 7 and roll < 0.18:
		return GameData.EnemyType.DODGER
	elif wave >= 5 and roll < 0.25:
		return GameData.EnemyType.TANK
	elif wave >= 3 and roll < 0.35:
		return GameData.EnemyType.FAST
	else:
		return GameData.EnemyType.REGULAR


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
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click(event.position)


func _handle_left_click(click_pos: Vector2) -> void:
	if GameData.is_game_over or GameData.is_victory:
		return

	var grid_pos := GameData.world_to_grid(click_pos)

	if not GameData.is_valid_grid_pos(grid_pos):
		return

	if grid[grid_pos.x][grid_pos.y] != null:
		return

	# Check cannon unlock
	if not GameData.is_cannon_unlocked(GameData.selected_cannon_type):
		return

	# Check if placing would block all paths
	if Pathfinding.would_block_all_paths(grid_pos):
		_show_blocked_message()
		return

	var cannon_stats: Dictionary = GameData.CANNON_STATS[GameData.selected_cannon_type]
	if not GameData.spend_money(cannon_stats.cost):
		return

	_place_cannon(grid_pos)


func _show_blocked_message() -> void:
	var label := Label.new()
	label.text = "BLOCKED!"
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.RED)
	label.position = Vector2(GameData.VIEWPORT_WIDTH / 2 - 50, GameData.VIEWPORT_HEIGHT / 2)
	ui_layer.add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)


func _handle_right_click(click_pos: Vector2) -> void:
	if GameData.is_game_over or GameData.is_victory:
		return

	var grid_pos := GameData.world_to_grid(click_pos)

	if not GameData.is_valid_grid_pos(grid_pos):
		return

	var cannon: Node2D = grid[grid_pos.x][grid_pos.y]
	if cannon == null:
		return

	# Sell cannon
	_sell_cannon(cannon, grid_pos)


func _place_cannon(grid_pos: Vector2i) -> void:
	var cannon := cannon_scene.instantiate()
	cannon.init(GameData.selected_cannon_type, bullet_layer, self)
	cannon.position = GameData.grid_to_world(grid_pos)
	cannon.grid_position = grid_pos

	cannon_layer.add_child(cannon)
	cannons.append(cannon)
	grid[grid_pos.x][grid_pos.y] = cannon

	# Update pathfinding obstacles
	Pathfinding.set_obstacle(grid_pos, true)
	_recalculate_enemy_paths()

	cannon.tree_exited.connect(_on_cannon_removed.bind(grid_pos))
	cannon.destroyed.connect(_on_cannon_destroyed.bind(cannon, grid_pos))


func _sell_cannon(cannon: Node2D, grid_pos: Vector2i) -> void:
	var sell_value := cannon.get_sell_value()
	GameData.add_money(sell_value)

	grid[grid_pos.x][grid_pos.y] = null
	cannons.erase(cannon)
	cannon.queue_free()

	# Update pathfinding
	Pathfinding.set_obstacle(grid_pos, false)
	_recalculate_enemy_paths()


func _on_cannon_removed(grid_pos: Vector2i) -> void:
	grid[grid_pos.x][grid_pos.y] = null


func _on_cannon_destroyed(cannon: Node2D, grid_pos: Vector2i) -> void:
	grid[grid_pos.x][grid_pos.y] = null
	cannons.erase(cannon)

	# Update pathfinding
	Pathfinding.set_obstacle(grid_pos, false)
	_recalculate_enemy_paths()


func _recalculate_enemy_paths() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			if enemy.has_method("recalculate_path"):
				enemy.recalculate_path()


func _on_game_over() -> void:
	if hud.has_method("show_game_over"):
		hud.show_game_over()


func _on_victory() -> void:
	if hud.has_method("show_victory"):
		hud.show_victory()


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


func get_cannons_in_range(from_pos: Vector2, attack_range: float) -> Array:
	var result: Array = []
	var closest_dist: float = attack_range + 1.0
	var closest_cannon: Node2D = null

	for cannon in cannons:
		if is_instance_valid(cannon) and not cannon.is_destroyed:
			var dist := from_pos.distance_to(cannon.position)
			if dist <= attack_range:
				result.append(cannon)
				if dist < closest_dist:
					closest_dist = dist
					closest_cannon = cannon

	# Sort by distance (closest first)
	if result.size() > 1 and closest_cannon:
		result.erase(closest_cannon)
		result.insert(0, closest_cannon)

	return result
