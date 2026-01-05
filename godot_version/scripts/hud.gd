extends Control
## HUD Controller - Minimalist UI for tower defense

@onready var money_label: Label = $TopBar/MoneyLabel
@onready var lives_label: Label = $TopBar/LivesLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var score_label: Label = $TopBar/ScoreLabel
@onready var cannon_buttons: HBoxContainer = $BottomBar/CannonButtons
@onready var game_over_panel: Panel = $GameOverPanel


func _ready() -> void:
	_connect_signals()
	_setup_cannon_buttons()
	_update_all_labels()
	game_over_panel.visible = false


func _connect_signals() -> void:
	GameData.money_changed.connect(_on_money_changed)
	GameData.lives_changed.connect(_on_lives_changed)
	GameData.wave_changed.connect(_on_wave_changed)
	GameData.score_changed.connect(_on_score_changed)


func _setup_cannon_buttons() -> void:
	for child in cannon_buttons.get_children():
		child.queue_free()

	# 8 cannon types
	for i in range(GameData.CannonType.size()):
		var button := Button.new()
		var stats: Dictionary = GameData.CANNON_STATS[i]
		var is_unlocked := GameData.is_cannon_unlocked(i)

		if is_unlocked:
			button.text = "%s\n$%d" % [stats.name, stats.cost]
		else:
			button.text = "%s\nLv.%d" % [stats.name, stats.unlock_level]

		button.custom_minimum_size = Vector2(90, 55)
		button.pressed.connect(_on_cannon_button_pressed.bind(i))
		button.add_theme_font_size_override("font_size", 12)

		# Color based on cannon type
		if is_unlocked:
			button.add_theme_color_override("font_color", stats.color.lightened(0.3))
		else:
			button.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			button.disabled = true

		cannon_buttons.add_child(button)

	_update_button_selection()


func _update_button_selection() -> void:
	for i in range(cannon_buttons.get_child_count()):
		var button: Button = cannon_buttons.get_child(i)
		if i == GameData.selected_cannon_type:
			button.add_theme_stylebox_override("normal", _create_selected_style())
			button.add_theme_stylebox_override("hover", _create_selected_style())
		else:
			button.remove_theme_stylebox_override("normal")
			button.remove_theme_stylebox_override("hover")


func _create_selected_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.2, 0.15, 1.0)
	style.border_color = Color(0.5, 0.7, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style


func _on_cannon_button_pressed(cannon_type: int) -> void:
	if GameData.is_cannon_unlocked(cannon_type):
		GameData.selected_cannon_type = cannon_type
		_update_button_selection()


func _update_all_labels() -> void:
	_on_money_changed(GameData.money)
	_on_lives_changed(GameData.lives)
	_on_wave_changed(GameData.wave)
	_on_score_changed(GameData.score)


func _on_money_changed(new_amount: int) -> void:
	money_label.text = "$%d" % new_amount
	_update_button_affordability()


func _on_lives_changed(new_lives: int) -> void:
	lives_label.text = "HP: %d" % new_lives
	if new_lives <= 3:
		lives_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		lives_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))


func _on_wave_changed(new_wave: int) -> void:
	wave_label.text = "Wave %d/%d" % [new_wave, GameData.waves_to_win]


func _on_score_changed(new_score: int) -> void:
	score_label.text = "%d" % new_score


func _update_button_affordability() -> void:
	for i in range(cannon_buttons.get_child_count()):
		var button: Button = cannon_buttons.get_child(i)
		var is_unlocked := GameData.is_cannon_unlocked(i)

		if not is_unlocked:
			button.disabled = true
			button.modulate = Color(0.4, 0.4, 0.4, 1.0)
			continue

		var stats: Dictionary = GameData.CANNON_STATS[i]
		if GameData.money < stats.cost:
			button.disabled = true
			button.modulate = Color(0.6, 0.6, 0.6, 1.0)
		else:
			button.disabled = false
			button.modulate = Color.WHITE


func show_game_over() -> void:
	game_over_panel.visible = true
	_setup_end_panel("GAME OVER", Color(0.8, 0.2, 0.2))


func show_victory() -> void:
	game_over_panel.visible = true
	var stars := _calculate_stars()
	_setup_end_panel("VICTORY!", Color(0.2, 0.8, 0.3), stars)


func _calculate_stars() -> int:
	var level_data: Dictionary = GameData.LEVEL_DATA[GameData.current_level - 1]
	var stars := 0
	for threshold in level_data.stars:
		if GameData.score >= threshold:
			stars += 1
	return stars


func _setup_end_panel(title: String, title_color: Color, stars: int = 0) -> void:
	# Clear existing content
	for child in game_over_panel.get_children():
		child.queue_free()

	var vbox := VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_CENTER
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	game_over_panel.add_child(vbox)

	# Title
	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", title_color)
	vbox.add_child(title_label)

	# Stars (if victory)
	if stars > 0:
		var stars_label := Label.new()
		var star_text := ""
		for i in range(3):
			star_text += "*" if i < stars else "-"
		stars_label.text = star_text
		stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stars_label.add_theme_font_size_override("font_size", 36)
		stars_label.add_theme_color_override("font_color", Color.GOLD)
		vbox.add_child(stars_label)

	# Score
	var score_label := Label.new()
	score_label.text = "\nScore: %d" % GameData.score
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(score_label)

	# Wave info
	var wave_label := Label.new()
	wave_label.text = "Wave: %d / %d" % [GameData.wave, GameData.waves_to_win]
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(wave_label)

	# Buttons
	var button_box := HBoxContainer.new()
	button_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_box)

	var retry_btn := Button.new()
	retry_btn.text = "Retry"
	retry_btn.custom_minimum_size = Vector2(100, 40)
	retry_btn.pressed.connect(_restart_game)
	button_box.add_child(retry_btn)

	var menu_btn := Button.new()
	menu_btn.text = "Menu"
	menu_btn.custom_minimum_size = Vector2(100, 40)
	menu_btn.pressed.connect(_go_to_menu)
	button_box.add_child(menu_btn)


func _on_game_over_panel_gui_input(event: InputEvent) -> void:
	pass  # Buttons handle interaction now


func _restart_game() -> void:
	GameData.reset_game()
	get_tree().reload_current_scene()


func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
