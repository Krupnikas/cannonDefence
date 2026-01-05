extends Node2D
class_name Enemy
## Enemy Class - With status effects and special mechanics

# Enemy properties
var enemy_type: int = GameData.EnemyType.REGULAR
var max_hp: float = 40.0
var hp: float = 40.0
var base_speed: float = 70.0
var speed: float = 70.0
var enemy_damage: float = 10.0
var enemy_color: Color = Color.RED
var physical_resist: float = 0.0
var effect_immune: bool = false
var special: String = "none"

# Movement
var target_x: float = -50.0
var is_dead: bool = false
var is_flying: bool = false

# Visual
var body_radius: float = 25.0

# Status effects
var is_burning: bool = false
var burn_damage: float = 5.0
var burn_timer: float = 0.0
const BURN_DURATION: float = 3.0

var is_frozen: bool = false
var freeze_slow: float = 0.5
var freeze_timer: float = 0.0
const FREEZE_DURATION: float = 2.0

# Signals
signal died
signal reached_end

# References
var bullet_layer: Node2D = null


func init(type: int, bullets_parent: Node2D) -> void:
	enemy_type = type
	bullet_layer = bullets_parent

	var stats: Dictionary = GameData.ENEMY_STATS[enemy_type]
	max_hp = stats.hp * GameData.get_enemy_hp_multiplier()
	hp = max_hp
	base_speed = stats.speed
	speed = base_speed
	enemy_damage = stats.damage
	enemy_color = stats.color
	physical_resist = stats.physical_resist
	effect_immune = stats.effect_immune
	special = stats.special
	is_flying = (special == "flying")

	# Adjust visual size based on type
	match enemy_type:
		GameData.EnemyType.REGULAR:
			body_radius = 22.0
		GameData.EnemyType.FAST:
			body_radius = 18.0
		GameData.EnemyType.TANK:
			body_radius = 35.0
		GameData.EnemyType.FLYING:
			body_radius = 20.0
		GameData.EnemyType.DODGER:
			body_radius = 20.0
		GameData.EnemyType.RESISTANT:
			body_radius = 26.0

	queue_redraw()


func _process(delta: float) -> void:
	if is_dead or GameData.is_game_over or GameData.is_paused:
		return

	_update_status_effects(delta)
	_move(delta)
	_check_reached_end()
	queue_redraw()


func _update_status_effects(delta: float) -> void:
	# Burning deals damage over time
	if is_burning:
		burn_timer -= delta
		hp -= burn_damage * delta
		if hp <= 0:
			_die(true)
			return
		if burn_timer <= 0:
			is_burning = false

	# Freeze slows movement
	if is_frozen:
		freeze_timer -= delta
		speed = base_speed * freeze_slow
		if freeze_timer <= 0:
			is_frozen = false
			speed = base_speed
	else:
		speed = base_speed


func _move(delta: float) -> void:
	var direction := Vector2(-1, 0)

	# Flying enemies move in a wave pattern
	if is_flying:
		var wave := sin(position.x * 0.015) * 0.4
		direction = Vector2(-1, wave).normalized()

	position += direction * speed * delta


func _check_reached_end() -> void:
	if position.x < target_x:
		emit_signal("reached_end")
		_die(false)


func take_damage(amount: float, effect_type: String = "none", apply_effect: bool = true) -> void:
	if is_dead:
		return

	hp -= amount

	# Apply status effects (fire and ice cancel each other)
	if apply_effect and not effect_immune:
		match effect_type:
			"burn":
				if is_frozen:
					# Fire cancels ice
					is_frozen = false
					freeze_timer = 0.0
					speed = base_speed
					_spawn_status_text("THAW")
				else:
					is_burning = true
					burn_timer = BURN_DURATION
			"freeze":
				if is_burning:
					# Ice cancels fire
					is_burning = false
					burn_timer = 0.0
					_spawn_status_text("DOUSED")
				else:
					is_frozen = true
					freeze_timer = FREEZE_DURATION

	if hp <= 0:
		_die(true)


func _spawn_status_text(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = global_position - Vector2(25, 40)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.WHITE)
	get_parent().add_child(label)

	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.timeout.connect(label.queue_free)
	label.add_child(timer)
	timer.start()


func _die(killed: bool) -> void:
	if is_dead:
		return

	is_dead = true

	if killed:
		emit_signal("died")
		_spawn_death_effect()

	queue_free()


func _spawn_death_effect() -> void:
	var particles := GPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 10

	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = body_radius
	material.direction = Vector3(0, -1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 60.0
	material.initial_velocity_max = 120.0
	material.gravity = Vector3(0, 250, 0)
	material.scale_min = 4.0
	material.scale_max = 8.0
	material.color = enemy_color
	particles.process_material = material

	get_parent().add_child(particles)

	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(particles.queue_free)
	particles.add_child(timer)
	timer.start()


func _draw() -> void:
	if is_dead:
		return

	# Shadow for flying enemies
	if is_flying:
		draw_circle(Vector2(8, 12), body_radius * 0.8, Color(0, 0, 0, 0.3))

	# Status effect auras
	if is_burning:
		draw_circle(Vector2.ZERO, body_radius + 5, Color(1.0, 0.3, 0.0, 0.4))
	if is_frozen:
		draw_circle(Vector2.ZERO, body_radius + 5, Color(0.3, 0.7, 1.0, 0.4))

	# Body
	draw_circle(Vector2.ZERO, body_radius, enemy_color)
	draw_arc(Vector2.ZERO, body_radius, 0, TAU, 32, enemy_color.darkened(0.3), 2.0)

	# Health bar
	var bar_width := body_radius * 2.0
	var bar_height := 6.0
	var bar_y := -body_radius - 14.0
	draw_rect(Rect2(-bar_width/2, bar_y, bar_width, bar_height), Color(0.2, 0.1, 0.1))

	var hp_ratio := hp / max_hp
	var fill_color: Color
	if hp_ratio > 0.6:
		fill_color = Color(0.2, 0.8, 0.2)
	elif hp_ratio > 0.3:
		fill_color = Color(0.9, 0.8, 0.2)
	else:
		fill_color = Color(0.9, 0.2, 0.2)
	draw_rect(Rect2(-bar_width/2, bar_y, bar_width * hp_ratio, bar_height), fill_color)

	# Type indicator
	match enemy_type:
		GameData.EnemyType.REGULAR:
			draw_circle(Vector2.ZERO, body_radius * 0.3, enemy_color.lightened(0.3))

		GameData.EnemyType.FAST:
			for i in range(3):
				var y_off := (i - 1) * 5.0
				draw_line(Vector2(body_radius * 0.3, y_off), Vector2(body_radius * 0.7, y_off), Color.WHITE, 2.0)

		GameData.EnemyType.TANK:
			draw_arc(Vector2.ZERO, body_radius * 0.7, 0, TAU, 16, enemy_color.darkened(0.4), 4.0)
			draw_circle(Vector2.ZERO, body_radius * 0.4, enemy_color.darkened(0.2))

		GameData.EnemyType.FLYING:
			draw_line(Vector2(-body_radius, -5), Vector2(-body_radius - 15, -12), Color.WHITE, 2.0)
			draw_line(Vector2(body_radius, -5), Vector2(body_radius + 15, -12), Color.WHITE, 2.0)
			draw_circle(Vector2.ZERO, body_radius * 0.35, enemy_color.lightened(0.2))

		GameData.EnemyType.DODGER:
			for i in range(3):
				var angle := i * TAU / 3.0 - PI/2
				var pos := Vector2.from_angle(angle) * body_radius * 0.5
				draw_circle(pos, 4.0, Color.YELLOW)

		GameData.EnemyType.RESISTANT:
			draw_arc(Vector2.ZERO, body_radius * 0.6, -PI * 0.7, PI * 0.7, 12, Color(0.3, 0.9, 0.3), 3.0)
			draw_circle(Vector2.ZERO, body_radius * 0.25, enemy_color.lightened(0.2))

	# Status icons
	var icon_y := -body_radius - 24.0
	if is_burning:
		draw_circle(Vector2(-10, icon_y), 5, Color.ORANGE)
	if is_frozen:
		draw_circle(Vector2(10, icon_y), 5, Color.CYAN)
