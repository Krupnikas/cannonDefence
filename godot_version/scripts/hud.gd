extends Control
## HUD Controller - Minimalist UI for tower defense

@onready var money_label: Label = $TopBar/MoneyLabel
@onready var lives_label: Label = $TopBar/LivesLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var score_label: Label = $TopBar/ScoreLabel
@onready var cannon_buttons: HBoxContainer = $BottomBar/CannonButtons
@onready var game_over_panel: Panel = $GameOverPanel


@onready var pause_panel: Panel = $PausePanel

var is_paused := false


func _ready() -> void:
	# Allow HUD to process when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	_connect_signals()
	_setup_cannon_buttons()
	_update_all_labels()
	game_over_panel.visible = false
	_setup_pause_panel()


func _input(event: InputEvent) -> void:
	# Cannon selection with number keys (1-9)
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event.keycode
		if key >= KEY_1 and key <= KEY_9:
			var cannon_index := key - KEY_1  # 0-8
			if cannon_index < GameData.CannonType.size():
				# Skip MINER if disabled
				if cannon_index == GameData.CannonType.MINER and not Settings.ENABLE_MINER_CANNON:
					return
				if GameData.is_cannon_unlocked(cannon_index):
					GameData.selected_cannon_type = cannon_index
					_update_button_selection()

		# Pause with P or Escape
		if key == KEY_P or key == KEY_ESCAPE:
			if not game_over_panel.visible:
				_toggle_pause()


func _connect_signals() -> void:
	GameData.money_changed.connect(_on_money_changed)
	GameData.lives_changed.connect(_on_lives_changed)
	GameData.wave_changed.connect(_on_wave_changed)
	GameData.score_changed.connect(_on_score_changed)


func _setup_cannon_buttons() -> void:
	for child in cannon_buttons.get_children():
		child.queue_free()

	# All cannon types (dynamically sized)
	for i in range(GameData.CannonType.size()):
		# Skip miner if feature is disabled
		if i == GameData.CannonType.MINER and not Settings.ENABLE_MINER_CANNON:
			continue
		var button := Button.new()
		var stats: Dictionary = GameData.CANNON_STATS[i]
		var is_unlocked := GameData.is_cannon_unlocked(i)

		# Store cannon type as metadata for proper tracking
		button.set_meta("cannon_type", i)

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
		var cannon_type: int = button.get_meta("cannon_type")
		if cannon_type == GameData.selected_cannon_type:
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
		var cannon_type: int = button.get_meta("cannon_type")
		var is_unlocked := GameData.is_cannon_unlocked(cannon_type)

		if not is_unlocked:
			button.disabled = true
			button.modulate = Color(0.4, 0.4, 0.4, 1.0)
			continue

		var stats: Dictionary = GameData.CANNON_STATS[cannon_type]
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

	# Style the panel
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	panel_style.border_color = title_color.darkened(0.3)
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(15)
	game_over_panel.add_theme_stylebox_override("panel", panel_style)

	# Center and size the panel
	game_over_panel.anchors_preset = Control.PRESET_CENTER
	game_over_panel.size = Vector2(400, 320)
	game_over_panel.position = Vector2(
		(GameData.VIEWPORT_WIDTH - 400) / 2,
		(GameData.VIEWPORT_HEIGHT - 320) / 2
	)

	var vbox := VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	game_over_panel.add_child(vbox)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer)

	# Title
	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 52)
	title_lbl.add_theme_color_override("font_color", title_color)
	vbox.add_child(title_lbl)

	# Stars display (always show for victory, show empty for game over)
	var stars_lbl := Label.new()
	var star_text := ""
	for i in range(3):
		star_text += "★" if i < stars else "☆"
	stars_lbl.text = star_text
	stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_lbl.add_theme_font_size_override("font_size", 42)
	if stars >= 3:
		stars_lbl.add_theme_color_override("font_color", Color.GOLD)
	elif stars >= 2:
		stars_lbl.add_theme_color_override("font_color", Color.SILVER)
	elif stars >= 1:
		stars_lbl.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))
	else:
		stars_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	vbox.add_child(stars_lbl)

	# Score with high score indicator
	var score_lbl := Label.new()
	var high_score := GameData.get_high_score(GameData.current_level)
	var is_new_high := GameData.score > high_score
	if is_new_high and stars > 0:
		score_lbl.text = "Score: %d (NEW HIGH!)" % GameData.score
		score_lbl.add_theme_color_override("font_color", Color.GOLD)
	else:
		score_lbl.text = "Score: %d" % GameData.score
		score_lbl.add_theme_color_override("font_color", Color.WHITE)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_font_size_override("font_size", 26)
	vbox.add_child(score_lbl)

	# Wave info
	var wave_lbl := Label.new()
	wave_lbl.text = "Wave: %d / %d" % [GameData.wave, GameData.waves_to_win]
	wave_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_lbl.add_theme_font_size_override("font_size", 20)
	wave_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(wave_lbl)

	# Spacer before buttons
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)

	# Buttons
	var button_box := HBoxContainer.new()
	button_box.alignment = BoxContainer.ALIGNMENT_CENTER
	button_box.add_theme_constant_override("separation", 20)
	vbox.add_child(button_box)

	var retry_btn := Button.new()
	retry_btn.text = "Retry"
	retry_btn.custom_minimum_size = Vector2(120, 45)
	retry_btn.add_theme_font_size_override("font_size", 18)
	retry_btn.pressed.connect(_restart_game)
	button_box.add_child(retry_btn)

	var menu_btn := Button.new()
	menu_btn.text = "Menu"
	menu_btn.custom_minimum_size = Vector2(120, 45)
	menu_btn.add_theme_font_size_override("font_size", 18)
	menu_btn.pressed.connect(_go_to_menu)
	button_box.add_child(menu_btn)


func _on_game_over_panel_gui_input(event: InputEvent) -> void:
	pass  # Buttons handle interaction now


func _restart_game() -> void:
	get_tree().paused = false
	GameData.reset_game()
	get_tree().reload_current_scene()


func _go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _setup_pause_panel() -> void:
	if not has_node("PausePanel"):
		# Create pause panel dynamically
		var panel := Panel.new()
		panel.name = "PausePanel"
		panel.visible = false
		panel.anchors_preset = Control.PRESET_CENTER
		panel.size = Vector2(300, 200)
		panel.position = Vector2(-150, -100)
		add_child(panel)
		pause_panel = panel

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
		style.border_color = Color(0.4, 0.4, 0.5)
		style.set_border_width_all(3)
		style.set_corner_radius_all(10)
		panel.add_theme_stylebox_override("panel", style)

		var vbox := VBoxContainer.new()
		vbox.anchors_preset = Control.PRESET_FULL_RECT
		vbox.add_theme_constant_override("separation", 15)
		panel.add_child(vbox)

		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 20)
		vbox.add_child(spacer)

		var title := Label.new()
		title.text = "PAUSED"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 36)
		title.add_theme_color_override("font_color", Color.WHITE)
		vbox.add_child(title)

		var resume_btn := Button.new()
		resume_btn.text = "Resume (P)"
		resume_btn.custom_minimum_size = Vector2(200, 40)
		resume_btn.pressed.connect(_toggle_pause)
		vbox.add_child(resume_btn)

		var menu_btn := Button.new()
		menu_btn.text = "Main Menu"
		menu_btn.custom_minimum_size = Vector2(200, 40)
		menu_btn.pressed.connect(_go_to_menu)
		vbox.add_child(menu_btn)

		# Center the vbox content
		for child in vbox.get_children():
			if child is Control:
				child.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	else:
		pause_panel.visible = false


func _toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_panel.visible = is_paused
