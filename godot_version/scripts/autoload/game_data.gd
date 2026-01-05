extends Node
## Game Data Autoload - Global constants, game state, and level progression

# Viewport Configuration (constant)
const VIEWPORT_WIDTH: int = 1600
const VIEWPORT_HEIGHT: int = 900

# Grid Configuration (dynamic per level)
var GRID_COLS: int = 8
var GRID_ROWS: int = 5
var CELL_WIDTH: float = VIEWPORT_WIDTH / float(GRID_COLS)
var CELL_HEIGHT: float = VIEWPORT_HEIGHT / float(GRID_ROWS)

# Level Configuration
const TOTAL_LEVELS: int = 15
const LEVELS_PER_ROW: int = 5
const LEVEL_ROWS: int = 3

# Cannon Types
enum CannonType {
	GUN,         # Basic - balanced
	SNIPER,      # Long range, slow, high damage
	RAPID,       # Fast fire, low damage
	FIRE,        # DoT burn effect
	ICE,         # Slows enemies
	ACID,        # Armor piercing, splash
	LASER,       # Instant hit, piercing
	TESLA,       # Chain lightning
	MINER        # Generates coins, no attack
}

# Enemy Types
enum EnemyType {
	REGULAR,     # Standard enemy
	FAST,        # High speed, low HP
	TANK,        # Slow, high HP
	FLYING,      # Ignores ground obstacles, takes less from physical
	DODGER,      # Chance to dodge attacks
	RESISTANT    # Immune to status effects (burn, freeze, slow)
}

# Bullet Types
enum BulletType {
	SHOT,
	SNIPER_SHOT,
	RAPID_SHOT,
	FIRE_SHOT,
	ICE_SHOT,
	ACID_SHOT,
	LASER_BEAM,
	TESLA_ARC
}

# Cannon Stats: {damage, fire_rate, range, cost, sell_value, bullet_type, unlock_level, special}
const CANNON_STATS: Dictionary = {
	CannonType.GUN: {
		"name": "Gun",
		"damage": 12.0,
		"fire_rate": 1.2,
		"range": 280.0,
		"cost": 50,
		"sell_value": 35,
		"bullet_type": BulletType.SHOT,
		"color": Color(0.5, 0.5, 0.55),
		"unlock_level": 1,
		"special": "none",
		"hp": 100.0
	},
	CannonType.SNIPER: {
		"name": "Sniper",
		"damage": 80.0,
		"fire_rate": 0.3,
		"range": 500.0,
		"cost": 120,
		"sell_value": 85,
		"bullet_type": BulletType.SNIPER_SHOT,
		"color": Color(0.2, 0.3, 0.2),
		"unlock_level": 2,
		"special": "critical",  # 25% chance for 2x damage
		"hp": 80.0  # Fragile
	},
	CannonType.RAPID: {
		"name": "Rapid",
		"damage": 5.0,
		"fire_rate": 4.0,
		"range": 220.0,
		"cost": 80,
		"sell_value": 55,
		"bullet_type": BulletType.RAPID_SHOT,
		"color": Color(0.6, 0.6, 0.3),
		"unlock_level": 3,
		"special": "none",
		"hp": 90.0
	},
	CannonType.FIRE: {
		"name": "Fire",
		"damage": 8.0,
		"fire_rate": 0.8,
		"range": 250.0,
		"cost": 100,
		"sell_value": 70,
		"bullet_type": BulletType.FIRE_SHOT,
		"color": Color(1.0, 0.4, 0.1),
		"unlock_level": 4,
		"special": "burn",  # 5 damage/sec for 3 sec
		"hp": 100.0
	},
	CannonType.ICE: {
		"name": "Ice",
		"damage": 10.0,
		"fire_rate": 0.7,
		"range": 260.0,
		"cost": 110,
		"sell_value": 75,
		"bullet_type": BulletType.ICE_SHOT,
		"color": Color(0.4, 0.8, 1.0),
		"unlock_level": 6,
		"special": "slow",  # 50% slow for 2 sec
		"hp": 100.0
	},
	CannonType.ACID: {
		"name": "Acid",
		"damage": 15.0,
		"fire_rate": 0.6,
		"range": 240.0,
		"cost": 140,
		"sell_value": 100,
		"bullet_type": BulletType.ACID_SHOT,
		"color": Color(0.2, 0.9, 0.2),
		"unlock_level": 8,
		"special": "splash",  # Damages nearby enemies
		"hp": 120.0  # Sturdy
	},
	CannonType.LASER: {
		"name": "Laser",
		"damage": 25.0,
		"fire_rate": 1.5,
		"range": 400.0,
		"cost": 180,
		"sell_value": 125,
		"bullet_type": BulletType.LASER_BEAM,
		"color": Color(1.0, 0.2, 0.3),
		"unlock_level": 10,
		"special": "pierce",  # Hits all enemies in line
		"hp": 90.0
	},
	CannonType.TESLA: {
		"name": "Tesla",
		"damage": 20.0,
		"fire_rate": 0.5,
		"range": 300.0,
		"cost": 200,
		"sell_value": 140,
		"bullet_type": BulletType.TESLA_ARC,
		"color": Color(0.6, 0.4, 1.0),
		"unlock_level": 12,
		"special": "chain",  # Chains to 3 nearby enemies
		"hp": 100.0
	},
	CannonType.MINER: {
		"name": "Miner",
		"damage": 0.0,
		"fire_rate": 0.0,
		"range": 0.0,
		"cost": 150,
		"sell_value": 105,
		"bullet_type": -1,  # No bullet
		"color": Color(0.85, 0.7, 0.2),  # Gold color
		"unlock_level": 5,
		"special": "miner",
		"coin_rate": 2.5,  # Coins per second (60s payback: 150/2.5=60)
		"hp": 80.0  # Fragile - needs protection
	}
}

# Enemy Stats: {hp, speed, damage, reward, special, color}
const ENEMY_STATS: Dictionary = {
	EnemyType.REGULAR: {
		"hp": 40.0,
		"speed": 70.0,
		"damage": 10.0,
		"reward": 15,
		"color": Color(0.9, 0.3, 0.3),
		"special": "none",
		"physical_resist": 0.0,
		"effect_immune": false
	},
	EnemyType.FAST: {
		"hp": 20.0,
		"speed": 140.0,
		"damage": 5.0,
		"reward": 20,
		"color": Color(1.0, 0.6, 0.2),
		"special": "none",
		"physical_resist": 0.0,
		"effect_immune": false
	},
	EnemyType.TANK: {
		"hp": 150.0,
		"speed": 35.0,
		"damage": 25.0,
		"reward": 50,
		"color": Color(0.5, 0.2, 0.2),
		"special": "none",
		"physical_resist": 0.3,  # 30% physical damage reduction
		"effect_immune": false
	},
	EnemyType.FLYING: {
		"hp": 35.0,
		"speed": 90.0,
		"damage": 10.0,
		"reward": 30,
		"color": Color(0.6, 0.6, 0.9),
		"special": "flying",  # Ignores obstacles
		"physical_resist": 0.5,  # 50% physical damage reduction
		"effect_immune": false
	},
	EnemyType.DODGER: {
		"hp": 30.0,
		"speed": 80.0,
		"damage": 8.0,
		"reward": 35,
		"color": Color(0.9, 0.9, 0.3),
		"special": "dodge",  # 40% chance to dodge
		"physical_resist": 0.0,
		"effect_immune": false
	},
	EnemyType.RESISTANT: {
		"hp": 60.0,
		"speed": 55.0,
		"damage": 15.0,
		"reward": 40,
		"color": Color(0.4, 0.7, 0.4),
		"special": "none",
		"physical_resist": 0.2,
		"effect_immune": true  # Immune to burn, freeze, slow
	}
}

# Bullet Stats: {speed, size, color, glow_color, trail}
const BULLET_STATS: Dictionary = {
	BulletType.SHOT: {
		"speed": 450.0,
		"size": 6.0,
		"color": Color(0.7, 0.7, 0.75),
		"glow_color": Color(0.9, 0.9, 0.95, 0.3),
		"trail": false
	},
	BulletType.SNIPER_SHOT: {
		"speed": 800.0,
		"size": 4.0,
		"color": Color(0.3, 0.4, 0.3),
		"glow_color": Color(0.5, 0.6, 0.5, 0.4),
		"trail": true
	},
	BulletType.RAPID_SHOT: {
		"speed": 500.0,
		"size": 4.0,
		"color": Color(0.8, 0.8, 0.4),
		"glow_color": Color(1.0, 1.0, 0.5, 0.3),
		"trail": false
	},
	BulletType.FIRE_SHOT: {
		"speed": 350.0,
		"size": 10.0,
		"color": Color(1.0, 0.5, 0.1),
		"glow_color": Color(1.0, 0.3, 0.0, 0.5),
		"trail": true
	},
	BulletType.ICE_SHOT: {
		"speed": 380.0,
		"size": 9.0,
		"color": Color(0.5, 0.9, 1.0),
		"glow_color": Color(0.3, 0.8, 1.0, 0.5),
		"trail": true
	},
	BulletType.ACID_SHOT: {
		"speed": 320.0,
		"size": 12.0,
		"color": Color(0.3, 1.0, 0.3),
		"glow_color": Color(0.2, 1.0, 0.2, 0.6),
		"trail": true
	},
	BulletType.LASER_BEAM: {
		"speed": 2000.0,  # Near instant
		"size": 3.0,
		"color": Color(1.0, 0.2, 0.2),
		"glow_color": Color(1.0, 0.0, 0.0, 0.7),
		"trail": true
	},
	BulletType.TESLA_ARC: {
		"speed": 600.0,
		"size": 8.0,
		"color": Color(0.7, 0.5, 1.0),
		"glow_color": Color(0.6, 0.3, 1.0, 0.6),
		"trail": true
	}
}

# Level definitions: {waves, money, lives, difficulty, stars, grid_cols, grid_rows}
const LEVEL_DATA: Array[Dictionary] = [
	# Row 1: Easy levels (1-5) - Standard 8x5 grid
	{"waves": 5, "money": 250, "lives": 15, "difficulty": 0.8, "stars": [1000, 2500, 5000], "cols": 8, "rows": 5},
	{"waves": 6, "money": 225, "lives": 12, "difficulty": 0.9, "stars": [1500, 3500, 7000], "cols": 8, "rows": 5},
	{"waves": 7, "money": 200, "lives": 12, "difficulty": 1.0, "stars": [2000, 4500, 9000], "cols": 8, "rows": 5},
	{"waves": 8, "money": 200, "lives": 10, "difficulty": 1.1, "stars": [2500, 5500, 11000], "cols": 8, "rows": 5},
	{"waves": 10, "money": 175, "lives": 10, "difficulty": 1.2, "stars": [3000, 7000, 14000], "cols": 8, "rows": 5},
	# Row 2: Medium levels (6-10) - Varied grids
	{"waves": 10, "money": 200, "lives": 10, "difficulty": 1.3, "stars": [4000, 9000, 18000], "cols": 10, "rows": 5},
	{"waves": 12, "money": 175, "lives": 8, "difficulty": 1.4, "stars": [5000, 11000, 22000], "cols": 8, "rows": 6},
	{"waves": 12, "money": 150, "lives": 8, "difficulty": 1.5, "stars": [6000, 13000, 26000], "cols": 10, "rows": 6},
	{"waves": 15, "money": 150, "lives": 8, "difficulty": 1.6, "stars": [7500, 16000, 32000], "cols": 9, "rows": 5},
	{"waves": 15, "money": 125, "lives": 6, "difficulty": 1.8, "stars": [9000, 19000, 38000], "cols": 10, "rows": 5},
	# Row 3: Hard levels (11-15) - Larger grids
	{"waves": 18, "money": 150, "lives": 6, "difficulty": 2.0, "stars": [11000, 23000, 46000], "cols": 10, "rows": 6},
	{"waves": 20, "money": 125, "lives": 5, "difficulty": 2.2, "stars": [13000, 27000, 54000], "cols": 12, "rows": 6},
	{"waves": 22, "money": 100, "lives": 5, "difficulty": 2.5, "stars": [16000, 33000, 66000], "cols": 10, "rows": 7},
	{"waves": 25, "money": 100, "lives": 4, "difficulty": 2.8, "stars": [20000, 40000, 80000], "cols": 12, "rows": 7},
	{"waves": 30, "money": 75, "lives": 3, "difficulty": 3.0, "stars": [25000, 50000, 100000], "cols": 14, "rows": 7},
]

# Game State
var money: int = 200
var lives: int = 10
var wave: int = 0
var score: int = 0
var selected_cannon_type: int = CannonType.GUN
var is_game_over: bool = false
var is_paused: bool = false
var is_victory: bool = false

# Level State
var current_level: int = 1
var waves_to_win: int = 10
var difficulty_multiplier: float = 1.0

# Persistent Progress (saved)
var unlocked_level: int = 1
var level_stars: Array[int] = []  # Stars earned per level (0-3)
var total_stars: int = 0
var high_scores: Array[int] = []

const SAVE_PATH: String = "user://cannon_defence_save.dat"

# Signals
signal money_changed(new_amount: int)
signal lives_changed(new_lives: int)
signal wave_changed(new_wave: int)
signal score_changed(new_score: int)
signal game_over
signal victory
signal level_complete(stars: int)
signal grid_changed(cols: int, rows: int)


func _ready() -> void:
	_init_progress_arrays()
	load_progress()


func _init_progress_arrays() -> void:
	level_stars.clear()
	high_scores.clear()
	for i in range(TOTAL_LEVELS):
		level_stars.append(0)
		high_scores.append(0)


func reset_game() -> void:
	var level_data: Dictionary = LEVEL_DATA[current_level - 1]
	money = level_data.money
	lives = level_data.lives
	waves_to_win = level_data.waves
	difficulty_multiplier = level_data.difficulty

	# Set grid dimensions for this level
	var new_cols: int = level_data.get("cols", 8)
	var new_rows: int = level_data.get("rows", 5)
	_update_grid_dimensions(new_cols, new_rows)

	wave = 0
	score = 0
	is_game_over = false
	is_victory = false
	is_paused = false
	emit_signal("money_changed", money)
	emit_signal("lives_changed", lives)
	emit_signal("wave_changed", wave)
	emit_signal("score_changed", score)


func _update_grid_dimensions(cols: int, rows: int) -> void:
	GRID_COLS = cols
	GRID_ROWS = rows
	CELL_WIDTH = VIEWPORT_WIDTH / float(GRID_COLS)
	CELL_HEIGHT = VIEWPORT_HEIGHT / float(GRID_ROWS)
	emit_signal("grid_changed", cols, rows)


func set_level(level: int) -> void:
	current_level = clampi(level, 1, TOTAL_LEVELS)


func is_level_unlocked(level: int) -> bool:
	return level <= unlocked_level


func get_level_stars(level: int) -> int:
	if level < 1 or level > TOTAL_LEVELS:
		return 0
	return level_stars[level - 1]


func is_cannon_unlocked(cannon_type: int) -> bool:
	var stats: Dictionary = CANNON_STATS[cannon_type]
	return current_level >= stats.unlock_level


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
		lives = 0
		is_game_over = true
		emit_signal("game_over")


func add_score(amount: int) -> void:
	# Apply difficulty bonus to score
	var bonus := int(amount * (difficulty_multiplier - 1.0) * 0.5)
	score += amount + bonus
	emit_signal("score_changed", score)


func next_wave() -> void:
	wave += 1
	emit_signal("wave_changed", wave)

	# Wave completion bonus
	var wave_bonus := 20 + wave * 10
	add_money(wave_bonus)

	# Check for victory
	if wave >= waves_to_win:
		_handle_victory()


func _handle_victory() -> void:
	is_victory = true

	# Calculate stars based on score
	var level_data: Dictionary = LEVEL_DATA[current_level - 1]
	var stars := 0
	for threshold in level_data.stars:
		if score >= threshold:
			stars += 1

	# Bonus for remaining lives
	var life_bonus := lives * 100
	score += life_bonus
	emit_signal("score_changed", score)

	# Update progress
	if stars > level_stars[current_level - 1]:
		level_stars[current_level - 1] = stars
		_recalculate_total_stars()

	if score > high_scores[current_level - 1]:
		high_scores[current_level - 1] = score

	# Unlock next level
	if current_level < TOTAL_LEVELS and current_level >= unlocked_level:
		unlocked_level = current_level + 1

	save_progress()
	emit_signal("level_complete", stars)
	emit_signal("victory")


func _recalculate_total_stars() -> void:
	total_stars = 0
	for s in level_stars:
		total_stars += s


func get_enemy_hp_multiplier() -> float:
	return difficulty_multiplier


func get_enemy_count_multiplier() -> float:
	return 1.0 + (difficulty_multiplier - 1.0) * 0.5


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


# Save/Load System
func save_progress() -> void:
	var save_data := {
		"unlocked_level": unlocked_level,
		"level_stars": level_stars,
		"high_scores": high_scores,
		"total_stars": total_stars
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()


func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()

		if save_data is Dictionary:
			unlocked_level = save_data.get("unlocked_level", 1)
			var loaded_stars = save_data.get("level_stars", [])
			var loaded_scores = save_data.get("high_scores", [])

			for i in range(min(loaded_stars.size(), TOTAL_LEVELS)):
				level_stars[i] = loaded_stars[i]
			for i in range(min(loaded_scores.size(), TOTAL_LEVELS)):
				high_scores[i] = loaded_scores[i]

			_recalculate_total_stars()


func reset_all_progress() -> void:
	unlocked_level = 1
	_init_progress_arrays()
	save_progress()
