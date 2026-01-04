extends Control
## HUD Controller - Manages UI elements

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
	# Clear existing buttons
	for child in cannon_buttons.get_children():
		child.queue_free()

	# Create button for each cannon type
	var cannon_names := ["Gun", "Big Gun", "Monster", "Fire", "Plasma"]

	for i in range(cannon_names.size()):
		var button := Button.new()
		var stats: Dictionary = GameData.CANNON_STATS[i]

		button.text = "%s\n$%d" % [cannon_names[i], stats.cost]
		button.custom_minimum_size = Vector2(120, 60)
		button.pressed.connect(_on_cannon_button_pressed.bind(i))

		# Style the button
		button.add_theme_color_override("font_color", stats.color)

		cannon_buttons.add_child(button)

	_update_button_selection()


func _update_button_selection() -> void:
	for i in range(cannon_buttons.get_child_count()):
		var button: Button = cannon_buttons.get_child(i)
		if i == GameData.selected_cannon_type:
			button.add_theme_stylebox_override("normal", _create_selected_style())
		else:
			button.remove_theme_stylebox_override("normal")


func _create_selected_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.5, 0.3, 1.0)
	style.border_color = Color.WHITE
	style.set_border_width_all(3)
	style.set_corner_radius_all(5)
	return style


func _on_cannon_button_pressed(cannon_type: int) -> void:
	GameData.selected_cannon_type = cannon_type
	_update_button_selection()


func _update_all_labels() -> void:
	_on_money_changed(GameData.money)
	_on_lives_changed(GameData.lives)
	_on_wave_changed(GameData.wave)
	_on_score_changed(GameData.score)


func _on_money_changed(new_amount: int) -> void:
	money_label.text = "Money: $%d" % new_amount
	_update_button_affordability()


func _on_lives_changed(new_lives: int) -> void:
	lives_label.text = "Lives: %d" % new_lives
	if new_lives <= 3:
		lives_label.add_theme_color_override("font_color", Color.RED)
	else:
		lives_label.remove_theme_color_override("font_color")


func _on_wave_changed(new_wave: int) -> void:
	wave_label.text = "Wave: %d" % new_wave


func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score


func _update_button_affordability() -> void:
	for i in range(cannon_buttons.get_child_count()):
		var button: Button = cannon_buttons.get_child(i)
		var stats: Dictionary = GameData.CANNON_STATS[i]

		if GameData.money < stats.cost:
			button.disabled = true
			button.modulate = Color(0.5, 0.5, 0.5, 1.0)
		else:
			button.disabled = false
			button.modulate = Color.WHITE


func show_game_over() -> void:
	game_over_panel.visible = true

	# Find or create game over label
	var label: Label
	if game_over_panel.has_node("GameOverLabel"):
		label = game_over_panel.get_node("GameOverLabel")
	else:
		label = Label.new()
		label.name = "GameOverLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 48)
		game_over_panel.add_child(label)

	label.text = "GAME OVER\n\nFinal Score: %d\nWaves Survived: %d\n\nClick to Restart" % [GameData.score, GameData.wave]
	label.anchors_preset = Control.PRESET_FULL_RECT


func _on_game_over_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_restart_game()


func _restart_game() -> void:
	GameData.reset_game()
	get_tree().reload_current_scene()
