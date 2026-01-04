extends Node2D
class_name Enemy
## Base Enemy Class - All enemy types inherit from this

# Enemy properties
var enemy_type: int = GameData.EnemyType.SOLDIER
var max_hp: float = 30.0
var hp: float = 30.0
var speed: float = 80.0
var enemy_damage: float = 10.0
var enemy_color: Color = Color.RED

# Movement
var target_x: float = -50.0
var is_dead: bool = false

# Visual
var body_radius: float = 25.0

# Signals
signal died
signal reached_end

# References
var bullet_layer: Node2D = null


func init(type: int, bullets_parent: Node2D) -> void:
	enemy_type = type
	bullet_layer = bullets_parent

	var stats: Dictionary = GameData.ENEMY_STATS[enemy_type]
	max_hp = stats.hp
	hp = max_hp
	speed = stats.speed
	enemy_damage = stats.damage
	enemy_color = stats.color

	# Adjust visual size based on type
	match enemy_type:
		GameData.EnemyType.SOLDIER:
			body_radius = 20.0
		GameData.EnemyType.BIG_SOLDIER:
			body_radius = 30.0
		GameData.EnemyType.MONSTER_SOLDIER:
			body_radius = 45.0
		GameData.EnemyType.SMART_SOLDIER:
			body_radius = 22.0
		GameData.EnemyType.FAST_SOLDIER:
			body_radius = 18.0

	queue_redraw()


func _process(delta: float) -> void:
	if is_dead or GameData.is_game_over or GameData.is_paused:
		return

	_move(delta)
	_check_reached_end()


func _move(delta: float) -> void:
	# Move toward the left side
	var direction := Vector2(-1, 0)

	# Smart soldiers can zigzag
	if enemy_type == GameData.EnemyType.SMART_SOLDIER:
		var wave := sin(position.x * 0.02) * 0.5
		direction = Vector2(-1, wave).normalized()

	position += direction * speed * delta
	queue_redraw()


func _check_reached_end() -> void:
	if position.x < target_x:
		emit_signal("reached_end")
		_die(false)


func take_damage(amount: float) -> void:
	if is_dead:
		return

	hp -= amount
	queue_redraw()

	if hp <= 0:
		_die(true)


func _die(killed: bool) -> void:
	if is_dead:
		return

	is_dead = true

	if killed:
		emit_signal("died")
		# Death effect
		_spawn_death_effect()

	queue_free()


func _spawn_death_effect() -> void:
	# Create a simple particle effect
	var particles := GPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 8

	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = body_radius
	material.direction = Vector3(0, -1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 100.0
	material.gravity = Vector3(0, 200, 0)
	material.scale_min = 3.0
	material.scale_max = 6.0
	material.color = enemy_color
	particles.process_material = material

	get_parent().add_child(particles)

	# Auto-delete after animation
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(particles.queue_free)
	particles.add_child(timer)
	timer.start()


func _draw() -> void:
	if is_dead:
		return

	# Draw body
	draw_circle(Vector2.ZERO, body_radius, enemy_color)
	draw_arc(Vector2.ZERO, body_radius, 0, TAU, 32, enemy_color.darkened(0.3), 2.0)

	# Draw health bar background
	var bar_width := body_radius * 2.0
	var bar_height := 6.0
	var bar_y := -body_radius - 12.0
	draw_rect(Rect2(-bar_width/2, bar_y, bar_width, bar_height), Color.DARK_RED)

	# Draw health bar fill
	var hp_ratio := hp / max_hp
	var fill_color := Color.GREEN if hp_ratio > 0.5 else (Color.YELLOW if hp_ratio > 0.25 else Color.RED)
	draw_rect(Rect2(-bar_width/2, bar_y, bar_width * hp_ratio, bar_height), fill_color)

	# Draw health bar border
	draw_rect(Rect2(-bar_width/2, bar_y, bar_width, bar_height), Color.BLACK, false, 1.0)

	# Draw enemy type indicator
	match enemy_type:
		GameData.EnemyType.SOLDIER:
			# Simple dot
			draw_circle(Vector2.ZERO, body_radius * 0.3, enemy_color.lightened(0.3))
		GameData.EnemyType.BIG_SOLDIER:
			# Larger inner circle
			draw_circle(Vector2.ZERO, body_radius * 0.4, enemy_color.darkened(0.2))
		GameData.EnemyType.MONSTER_SOLDIER:
			# Star pattern
			for i in range(5):
				var angle := i * TAU / 5.0 - PI/2
				var point := Vector2.from_angle(angle) * body_radius * 0.5
				draw_circle(point, 5.0, enemy_color.darkened(0.3))
		GameData.EnemyType.SMART_SOLDIER:
			# Brain icon (circles)
			draw_circle(Vector2(-5, 0), 6.0, Color.PINK)
			draw_circle(Vector2(5, 0), 6.0, Color.PINK)
		GameData.EnemyType.FAST_SOLDIER:
			# Speed lines
			for i in range(3):
				var y_offset := (i - 1) * 6.0
				draw_line(Vector2(body_radius * 0.2, y_offset), Vector2(body_radius * 0.6, y_offset), Color.WHITE, 2.0)
