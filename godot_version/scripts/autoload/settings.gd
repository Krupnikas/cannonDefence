extends Node
## Settings & Feature Flags - Control experimental features

# Feature Flags
var ENABLE_CAMERA_CONTROLS: bool = true
var ENABLE_PATHFINDING: bool = true
var ENABLE_CANNON_HP: bool = true
var ENABLE_ENEMY_ATTACKS: bool = true
var ENABLE_MINER_CANNON: bool = true

# Debug Flags
var DEBUG_SHOW_PATHS: bool = false
var DEBUG_SHOW_RANGES: bool = false
var DEBUG_INFINITE_MONEY: bool = false
var DEBUG_INVINCIBLE_CANNONS: bool = false

# Camera Settings
var CAMERA_ZOOM_MIN: float = 0.5
var CAMERA_ZOOM_MAX: float = 2.0
var CAMERA_ZOOM_SPEED: float = 0.1
var CAMERA_PAN_SPEED: float = 400.0

const SETTINGS_PATH: String = "user://cannon_defence_settings.dat"

# Signals
signal settings_changed


func _ready() -> void:
	load_settings()


func save_settings() -> void:
	var data := {
		"ENABLE_CAMERA_CONTROLS": ENABLE_CAMERA_CONTROLS,
		"ENABLE_PATHFINDING": ENABLE_PATHFINDING,
		"ENABLE_CANNON_HP": ENABLE_CANNON_HP,
		"ENABLE_ENEMY_ATTACKS": ENABLE_ENEMY_ATTACKS,
		"ENABLE_MINER_CANNON": ENABLE_MINER_CANNON,
		"DEBUG_SHOW_PATHS": DEBUG_SHOW_PATHS,
		"DEBUG_SHOW_RANGES": DEBUG_SHOW_RANGES,
		"DEBUG_INFINITE_MONEY": DEBUG_INFINITE_MONEY,
		"DEBUG_INVINCIBLE_CANNONS": DEBUG_INVINCIBLE_CANNONS,
	}

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()

		if data is Dictionary:
			ENABLE_CAMERA_CONTROLS = data.get("ENABLE_CAMERA_CONTROLS", true)
			ENABLE_PATHFINDING = data.get("ENABLE_PATHFINDING", true)
			ENABLE_CANNON_HP = data.get("ENABLE_CANNON_HP", true)
			ENABLE_ENEMY_ATTACKS = data.get("ENABLE_ENEMY_ATTACKS", true)
			ENABLE_MINER_CANNON = data.get("ENABLE_MINER_CANNON", true)
			DEBUG_SHOW_PATHS = data.get("DEBUG_SHOW_PATHS", false)
			DEBUG_SHOW_RANGES = data.get("DEBUG_SHOW_RANGES", false)
			DEBUG_INFINITE_MONEY = data.get("DEBUG_INFINITE_MONEY", false)
			DEBUG_INVINCIBLE_CANNONS = data.get("DEBUG_INVINCIBLE_CANNONS", false)


func toggle_flag(flag_name: String) -> void:
	match flag_name:
		"ENABLE_CAMERA_CONTROLS":
			ENABLE_CAMERA_CONTROLS = not ENABLE_CAMERA_CONTROLS
		"ENABLE_PATHFINDING":
			ENABLE_PATHFINDING = not ENABLE_PATHFINDING
		"DEBUG_SHOW_PATHS":
			DEBUG_SHOW_PATHS = not DEBUG_SHOW_PATHS
		"DEBUG_SHOW_RANGES":
			DEBUG_SHOW_RANGES = not DEBUG_SHOW_RANGES
		"DEBUG_INFINITE_MONEY":
			DEBUG_INFINITE_MONEY = not DEBUG_INFINITE_MONEY
		"DEBUG_INVINCIBLE_CANNONS":
			DEBUG_INVINCIBLE_CANNONS = not DEBUG_INVINCIBLE_CANNONS

	save_settings()
	emit_signal("settings_changed")
