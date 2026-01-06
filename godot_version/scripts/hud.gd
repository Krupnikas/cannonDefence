extends Control
## HUD Controller - Fieldrunners-style popup UI

@onready var money_label: Label = $TopBar/MoneyLabel
@onready var lives_label: Label = $TopBar/LivesLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var score_label: Label = $TopBar/ScoreLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var pause_panel: Panel = $PausePanel

# Popup for cannon selection/upgrade
var popup_panel: Panel = null
var popup_grid_pos: Vector2i = Vector2i(-1, -1)
var popup_cannon: Node2D = null

var is_paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_signals()
	_update_all_labels()
	game_over_panel.visible = false
	pause_panel.visible = false
	_setup_pause_panel()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event.keycode

		# Fast forward with Space
		if key == KEY_SPACE and not GameData.is_game_over and not GameData.is_victory:
			Engine.time_scale = 2.0 if Engine.time_scale == 1.0 else 1.0

		# Pause with P or Escape
		if key == KEY_P or key == KEY_ESCAPE:
			if popup_panel and popup_panel.visible:
				_close_popup()
			elif not game_over_panel.visible:
				_toggle_pause()

		# Debug shortcuts
		if key == KEY_F1:
			Settings.DEBUG_SHOW_PATHS = not Settings.DEBUG_SHOW_PATHS
		elif key == KEY_F2:
			Settings.DEBUG_SHOW_RANGES = not Settings.DEBUG_SHOW_RANGES
		elif key == KEY_F3:
			Settings.DEBUG_INFINITE_MONEY = not Settings.DEBUG_INFINITE_MONEY
		elif key == KEY_F4:
			Settings.DEBUG_INVINCIBLE_CANNONS = not Settings.DEBUG_INVINCIBLE_CANNONS

	# Close popup on click outside
	if event is InputEventMouseButton and event.pressed:
		if popup_panel and popup_panel.visible:
			var popup_rect := Rect2(popup_panel.global_position, popup_panel.size)
			if not popup_rect.has_point(event.position):
				_close_popup()


func _connect_signals() -> void:
	GameData.money_changed.connect(_on_money_changed)
	GameData.lives_changed.connect(_on_lives_changed)
	GameData.wave_changed.connect(_on_wave_changed)
	GameData.score_changed.connect(_on_score_changed)


# Fieldrunners-style popup for empty cell
func show_cannon_popup(screen_pos: Vector2, grid_pos: Vector2i) -> void:
	_close_popup()
	popup_grid_pos = grid_pos
	popup_cannon = null

	popup_panel = Panel.new()
	popup_panel.size = Vector2(280, 200)

	# Position popup near click, but keep on screen
	var pos := screen_pos - Vector2(140, 100)
	pos.x = clampf(pos.x, 10, GameData.VIEWPORT_WIDTH - 290)
	pos.y = clampf(pos.y, 10, GameData.VIEWPORT_HEIGHT - 210)
	popup_panel.position = pos

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.95)
	style.border_color = Color(0.3, 0.4, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	popup_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.add_theme_constant_override("separation", 4)
	popup_panel.add_child(vbox)

	var title := Label.new()
	title.text = "BUILD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.7, 0.8, 0.7))
	vbox.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)

	for i in range(GameData.CannonType.size()):
		if i == GameData.CannonType.MINER and not Settings.ENABLE_MINER_CANNON:
			continue

		var stats: Dictionary = GameData.CANNON_STATS[i]
		var is_unlocked := GameData.is_cannon_unlocked(i)
		var can_afford := GameData.money >= stats.cost or Settings.DEBUG_INFINITE_MONEY

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(85, 50)
		btn.add_theme_font_size_override("font_size", 11)

		if is_unlocked:
			btn.text = "%s\n$%d" % [stats.name, stats.cost]
			btn.disabled = not can_afford
			if can_afford:
				btn.add_theme_color_override("font_color", stats.color.lightened(0.3))
				btn.pressed.connect(_on_popup_cannon_selected.bind(i))
			else:
				btn.modulate = Color(0.5, 0.5, 0.5)
		else:
			btn.text = "%s\nLv.%d" % [stats.name, stats.unlock_level]
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4)

		grid.add_child(btn)

	add_child(popup_panel)


# Popup for existing cannon (upgrade/sell)
func show_upgrade_popup(screen_pos: Vector2, cannon: Node2D) -> void:
	_close_popup()
	popup_cannon = cannon
	popup_grid_pos = cannon.grid_position

	popup_panel = Panel.new()
	popup_panel.size = Vector2(180, 120)

	var pos := screen_pos - Vector2(90, 60)
	pos.x = clampf(pos.x, 10, GameData.VIEWPORT_WIDTH - 190)
	pos.y = clampf(pos.y, 10, GameData.VIEWPORT_HEIGHT - 130)
	popup_panel.position = pos

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.95)
	style.border_color = Color(0.4, 0.35, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	popup_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.add_theme_constant_override("separation", 6)
	popup_panel.add_child(vbox)

	var stats: Dictionary = GameData.CANNON_STATS[cannon.cannon_type]
	var title := Label.new()
	title.text = stats.name.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", stats.color.lightened(0.3))
	vbox.add_child(title)

	# Sell button
	var sell_btn := Button.new()
	sell_btn.text = "SELL ($%d)" % cannon.get_sell_value()
	sell_btn.custom_minimum_size = Vector2(160, 35)
	sell_btn.add_theme_font_size_override("font_size", 14)
	sell_btn.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
	sell_btn.pressed.connect(_on_popup_sell)
	vbox.add_child(sell_btn)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(160, 30)
	close_btn.add_theme_font_size_override("font_size", 12)
	close_btn.pressed.connect(_close_popup)
	vbox.add_child(close_btn)

	add_child(popup_panel)


func _on_popup_cannon_selected(cannon_type: int) -> void:
	GameData.selected_cannon_type = cannon_type
	get_parent().get_parent().call("place_cannon_at", popup_grid_pos)
	_close_popup()


func _on_popup_sell() -> void:
	if popup_cannon and is_instance_valid(popup_cannon):
		get_parent().get_parent().call("sell_cannon_at", popup_grid_pos)
	_close_popup()


func _close_popup() -> void:
	if popup_panel:
		popup_panel.queue_free()
		popup_panel = null
	popup_grid_pos = Vector2i(-1, -1)
	popup_cannon = null


func _update_all_labels() -> void:
	_on_money_changed(GameData.money)
	_on_lives_changed(GameData.lives)
	_on_wave_changed(GameData.wave)
	_on_score_changed(GameData.score)


func _on_money_changed(new_amount: int) -> void:
	money_label.text = "$%d" % new_amount


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
	# Clear existing children
	for child in pause_panel.get_children():
		child.queue_free()

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.4, 0.4, 0.5)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	pause_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.add_theme_constant_override("separation", 15)
	pause_panel.add_child(vbox)

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
	resume_btn.text = "Resume"
	resume_btn.custom_minimum_size = Vector2(200, 50)
	resume_btn.add_theme_font_size_override("font_size", 18)
	resume_btn.pressed.connect(_toggle_pause)
	vbox.add_child(resume_btn)

	var menu_btn := Button.new()
	menu_btn.text = "Main Menu"
	menu_btn.custom_minimum_size = Vector2(200, 50)
	menu_btn.add_theme_font_size_override("font_size", 18)
	menu_btn.pressed.connect(_go_to_menu)
	vbox.add_child(menu_btn)

	# Center the vbox content
	for child in vbox.get_children():
		if child is Control:
			child.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_panel.visible = is_paused
