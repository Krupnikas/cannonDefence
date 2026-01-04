extends Node
## Game Data Autoload - Global constants and game state

# Grid Configuration
const GRID_COLS: int = 8
const GRID_ROWS: int = 5
const VIEWPORT_WIDTH: int = 1600
const VIEWPORT_HEIGHT: int = 900
const CELL_WIDTH: float = VIEWPORT_WIDTH / float(GRID_COLS)  # 200
const CELL_HEIGHT: float = VIEWPORT_HEIGHT / float(GRID_ROWS)  # 180

# Cannon Types
enum CannonType {
	GUN,
	BIG_GUN,
	MONSTER_GUN,
	FIRE_GUN,
	PLASMA_GUN
}

# Enemy Types
enum EnemyType {
	SOLDIER,
	BIG_SOLDIER,
	MONSTER_SOLDIER,
	SMART_SOLDIER,
	FAST_SOLDIER
}

# Bullet Types
enum BulletType {
	SHOT,
	BIG_SHOT,
	MONSTER_SHOT,
	FIRE_SHOT,
	PLASMA_SHOT
}

# Cannon Stats: {damage, fire_rate, range, cost, bullet_type}
const CANNON_STATS: Dictionary = {
	CannonType.GUN: {
		"damage": 10.0,
		"fire_rate": 1.0,
		"range": 300.0,
		"cost": 50,
		"bullet_type": BulletType.SHOT,
		"color": Color.GRAY
	},
	CannonType.BIG_GUN: {
		"damage": 25.0,
		"fire_rate": 0.6,
		"range": 350.0,
		"cost": 100,
		"bullet_type": BulletType.BIG_SHOT,
		"color": Color.DARK_GRAY
	},
	CannonType.MONSTER_GUN: {
		"damage": 50.0,
		"fire_rate": 0.3,
		"range": 400.0,
		"cost": 200,
		"bullet_type": BulletType.MONSTER_SHOT,
		"color": Color.BLACK
	},
	CannonType.FIRE_GUN: {
		"damage": 15.0,
		"fire_rate": 1.5,
		"range": 250.0,
		"cost": 150,
		"bullet_type": BulletType.FIRE_SHOT,
		"color": Color.ORANGE_RED
	},
	CannonType.PLASMA_GUN: {
		"damage": 35.0,
		"fire_rate": 0.8,
		"range": 320.0,
		"cost": 175,
		"bullet_type": BulletType.PLASMA_SHOT,
		"color": Color.CYAN
	}
}

# Enemy Stats: {hp, speed, damage, reward}
const ENEMY_STATS: Dictionary = {
	EnemyType.SOLDIER: {
		"hp": 30.0,
		"speed": 80.0,
		"damage": 10.0,
		"reward": 10,
		"color": Color.RED
	},
	EnemyType.BIG_SOLDIER: {
		"hp": 80.0,
		"speed": 50.0,
		"damage": 20.0,
		"reward": 25,
		"color": Color.DARK_RED
	},
	EnemyType.MONSTER_SOLDIER: {
		"hp": 200.0,
		"speed": 30.0,
		"damage": 50.0,
		"reward": 75,
		"color": Color.MAROON
	},
	EnemyType.SMART_SOLDIER: {
		"hp": 50.0,
		"speed": 70.0,
		"damage": 15.0,
		"reward": 30,
		"color": Color.PURPLE
	},
	EnemyType.FAST_SOLDIER: {
		"hp": 20.0,
		"speed": 150.0,
		"damage": 5.0,
		"reward": 15,
		"color": Color.SALMON
	}
}

# Bullet Stats: {speed, size}
const BULLET_STATS: Dictionary = {
	BulletType.SHOT: {
		"speed": 400.0,
		"size": 8.0,
		"color": Color.DARK_GRAY
	},
	BulletType.BIG_SHOT: {
		"speed": 350.0,
		"size": 12.0,
		"color": Color.BLACK
	},
	BulletType.MONSTER_SHOT: {
		"speed": 300.0,
		"size": 18.0,
		"color": Color.DIM_GRAY
	},
	BulletType.FIRE_SHOT: {
		"speed": 450.0,
		"size": 10.0,
		"color": Color.ORANGE
	},
	BulletType.PLASMA_SHOT: {
		"speed": 500.0,
		"size": 14.0,
		"color": Color.DEEP_SKY_BLUE
	}
}

# Game State
var money: int = 200
var lives: int = 10
var wave: int = 0
var score: int = 0
var selected_cannon_type: int = CannonType.GUN
var is_game_over: bool = false
var is_paused: bool = false

# Signals
signal money_changed(new_amount: int)
signal lives_changed(new_lives: int)
signal wave_changed(new_wave: int)
signal score_changed(new_score: int)
signal game_over


func reset_game() -> void:
	money = 200
	lives = 10
	wave = 0
	score = 0
	is_game_over = false
	is_paused = false
	emit_signal("money_changed", money)
	emit_signal("lives_changed", lives)
	emit_signal("wave_changed", wave)
	emit_signal("score_changed", score)


func add_money(amount: int) -> void:
	money += amount
	emit_signal("money_changed", money)


func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		emit_signal("money_changed", money)
		return true
	return false


func lose_life(amount: int = 1) -> void:
	lives -= amount
	emit_signal("lives_changed", lives)
	if lives <= 0:
		is_game_over = true
		emit_signal("game_over")


func add_score(amount: int) -> void:
	score += amount
	emit_signal("score_changed", score)


func next_wave() -> void:
	wave += 1
	emit_signal("wave_changed", wave)


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * CELL_WIDTH + CELL_WIDTH / 2.0,
		grid_pos.y * CELL_HEIGHT + CELL_HEIGHT / 2.0
	)


func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / CELL_WIDTH),
		int(world_pos.y / CELL_HEIGHT)
	)


func is_valid_grid_pos(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < GRID_COLS and grid_pos.y >= 0 and grid_pos.y < GRID_ROWS
