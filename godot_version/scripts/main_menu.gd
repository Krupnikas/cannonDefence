extends Control
## Main Menu with Level Selection

const BUTTON_SIZE := Vector2(140, 120)
const BUTTON_SPACING := Vector2(20, 20)
const GRID_OFFSET := Vector2(400, 250)

var level_buttons: Array[Button] = []

@onready var title_label: Label = $TitleLabel
@onready var stars_label: Label = $StarsLabel
@onready var level_grid: Control = $LevelGrid
@onready var reset_button: Button = $ResetButton


func _ready() -> void:
	_setup_ui()
	_create_level_buttons()
	_update_stars_display()


func _setup_ui() -> void:
	# Title
	title_label.text = "CANNON DEFENCE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.position = Vector2(GameData.VIEWPORT_WIDTH / 2 - 300, 50)
	title_label.size = Vector2(600, 100)

	# Stars display
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_label.add_theme_font_size_override("font_size", 28)
	stars_label.position = Vector2(GameData.VIEWPORT_WIDTH / 2 - 200, 150)
	stars_label.size = Vector2(400, 50)

	# Reset button
	reset_button.text = "Reset Progress"
	reset_button.position = Vector2(GameData.VIEWPORT_WIDTH - 200, 20)
	reset_button.size = Vector2(180, 40)
	reset_button.pressed.connect(_on_reset_pressed)


func _create_level_buttons() -> void:
	level_buttons.clear()

	for row in range(GameData.LEVEL_ROWS):
		for col in range(GameData.LEVELS_PER_ROW):
			var level := row * GameData.LEVELS_PER_ROW + col + 1
			var button := _create_level_button(level, col, row)
			level_grid.add_child(button)
			level_buttons.append(button)


func _create_level_button(level: int, col: int, row: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = BUTTON_SIZE
	button.size = BUTTON_SIZE

	var x := GRID_OFFSET.x + col * (BUTTON_SIZE.x + BUTTON_SPACING.x)
	var y := GRID_OFFSET.y + row * (BUTTON_SIZE.y + BUTTON_SPACING.y)
	button.position = Vector2(x, y)

	var is_unlocked := GameData.is_level_unlocked(level)
	var stars := GameData.get_level_stars(level)

	if is_unlocked:
		var level_data: Dictionary = GameData.LEVEL_DATA[level - 1]
		var star_text := _get_star_text(stars)
		button.text = "Level %d\n%d Waves\n%s" % [level, level_data.waves, star_text]
		button.disabled = false
		button.pressed.connect(_on_level_selected.bind(level))

		# Color based on difficulty row
		match row:
			0:
				button.modulate = Color(0.7, 1.0, 0.7)  # Green - Easy
			1:
				button.modulate = Color(1.0, 1.0, 0.7)  # Yellow - Medium
			2:
				button.modulate = Color(1.0, 0.7, 0.7)  # Red - Hard
	else:
		button.text = "Level %d\n[LOCKED]" % level
		button.disabled = true
		button.modulate = Color(0.5, 0.5, 0.5)

	# Apply style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.25, 0.3) if is_unlocked else Color(0.15, 0.15, 0.15)
	style.set_border_width_all(3)
	style.border_color = _get_border_color(stars) if is_unlocked else Color.DARK_GRAY
	style.set_corner_radius_all(10)
	button.add_theme_stylebox_override("normal", style)

	return button


func _get_star_text(stars: int) -> String:
	var filled := ""
	var empty := ""
	for i in range(3):
		if i < stars:
			filled += "*"
		else:
			empty += "-"
	return filled + empty


func _get_border_color(stars: int) -> Color:
	match stars:
		3:
			return Color.GOLD
		2:
			return Color.SILVER
		1:
			return Color(0.8, 0.5, 0.2)  # Bronze
		_:
			return Color.DIM_GRAY


func _update_stars_display() -> void:
	var max_stars := GameData.TOTAL_LEVELS * 3
	stars_label.text = "Total Stars: %d / %d" % [GameData.total_stars, max_stars]


func _on_level_selected(level: int) -> void:
	GameData.set_level(level)
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")


func _on_reset_pressed() -> void:
	# Show confirmation dialog
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "Reset all progress?\nThis cannot be undone!"
	dialog.confirmed.connect(_confirm_reset)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()


func _confirm_reset() -> void:
	GameData.reset_all_progress()
	# Refresh buttons
	for button in level_buttons:
		button.queue_free()
	level_buttons.clear()

	# Wait a frame then recreate
	await get_tree().process_frame
	_create_level_buttons()
	_update_stars_display()
