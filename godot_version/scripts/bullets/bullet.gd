extends Node2D
class_name Bullet
## Base Bullet Class - Colorful projectiles with special effects

# Bullet properties
var bullet_type: int = GameData.BulletType.SHOT
var damage: float = 10.0
var speed: float = 400.0
var bullet_size: float = 8.0
var bullet_color: Color = Color.DARK_GRAY
var glow_color: Color = Color.WHITE
var has_trail: bool = false
var special: String = "none"

# Movement
var target: Node2D = null
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 5.0

# State
var is_destroyed: bool = false

# Trail effect
var trail_points: PackedVector2Array = []
const MAX_TRAIL_POINTS: int = 8


func init(type: int, dmg: float, target_enemy: Node2D, start_pos: Vector2, special_effect: String = "none") -> void:
	bullet_type = type
	damage = dmg
	target = target_enemy
	special = special_effect

	var stats: Dictionary = GameData.BULLET_STATS[bullet_type]
	speed = stats.speed
	bullet_size = stats.size
	bullet_color = stats.color
	glow_color = stats.glow_color
	has_trail = stats.trail

	# Calculate direction from the provided start position
	if target and is_instance_valid(target):
		direction = start_pos.direction_to(target.global_position)
		rotation = direction.angle()

	queue_redraw()


func _process(delta: float) -> void:
	if is_destroyed or GameData.is_game_over or GameData.is_paused:
		return

	lifetime -= delta
	if lifetime <= 0:
		_destroy()
		return

	# Update trail
	if has_trail:
		trail_points.insert(0, position)
		if trail_points.size() > MAX_TRAIL_POINTS:
			trail_points.resize(MAX_TRAIL_POINTS)

	_move(delta)
	_check_collision()
	_check_bounds()
	queue_redraw()


func _move(delta: float) -> void:
	position += direction * speed * delta


func _check_collision() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")

	# Laser and Tesla have special collision
	if bullet_type == GameData.BulletType.LASER_BEAM:
		_laser_collision(enemies)
		return
	elif bullet_type == GameData.BulletType.TESLA_ARC:
		_tesla_collision(enemies)
		return

	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_dead:
			continue

		var dist := global_position.distance_to(enemy.global_position)
		if dist < bullet_size + enemy.body_radius:
			_hit_enemy(enemy)

			# Acid has splash damage
			if bullet_type == GameData.BulletType.ACID_SHOT:
				_acid_splash(enemies, enemy.global_position)

			return


func _laser_collision(enemies: Array) -> void:
	# Laser pierces through all enemies in its path
	var hit_any := false
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_dead:
			continue

		# Check if enemy is along the laser line
		var to_enemy: Vector2 = enemy.global_position - global_position
		var proj: float = to_enemy.dot(direction)

		if proj > 0 and proj < 500:  # Within range
			var perp_dist: float = abs(to_enemy.cross(direction))
			if perp_dist < enemy.body_radius + bullet_size:
				_hit_enemy(enemy, false)  # Don't destroy on hit
				hit_any = true

	if hit_any or lifetime < 4.9:  # Short lifetime for laser
		_destroy()


func _tesla_collision(enemies: Array) -> void:
	var hit_enemies: Array[Node2D] = []
	var chain_range := 150.0
	var max_chains := 3

	# Find first target
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_dead:
			continue

		var dist := global_position.distance_to(enemy.global_position)
		if dist < bullet_size + enemy.body_radius:
			hit_enemies.append(enemy)
			_hit_enemy(enemy, false)
			break

	# Chain to nearby enemies
	while hit_enemies.size() < max_chains and hit_enemies.size() > 0:
		var last_hit: Node2D = hit_enemies[hit_enemies.size() - 1]
		var found_next := false

		for enemy in enemies:
			if not is_instance_valid(enemy) or enemy.is_dead:
				continue
			if enemy in hit_enemies:
				continue

			var dist := last_hit.global_position.distance_to(enemy.global_position)
			if dist < chain_range:
				hit_enemies.append(enemy)
				_hit_enemy(enemy, false)
				_spawn_chain_effect(last_hit.global_position, enemy.global_position)
				found_next = true
				break

		if not found_next:
			break

	if hit_enemies.size() > 0 or lifetime < 4.8:
		_destroy()


func _acid_splash(enemies: Array, center: Vector2) -> void:
	var splash_range := 60.0
	var splash_damage := damage * 0.5

	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_dead:
			continue

		var dist := center.distance_to(enemy.global_position)
		if dist < splash_range and dist > 0:
			if enemy.has_method("take_damage"):
				enemy.take_damage(splash_damage, "acid", false)

	_spawn_splash_effect(center)


func _hit_enemy(enemy: Node2D, destroy_bullet: bool = true) -> void:
	if not enemy.has_method("take_damage"):
		if destroy_bullet:
			_destroy()
		return

	# Check for dodge
	var enemy_stats: Dictionary = GameData.ENEMY_STATS[enemy.enemy_type]
	if enemy_stats.special == "dodge" and randf() < 0.4:
		_spawn_dodge_effect(enemy.global_position)
		if destroy_bullet:
			_destroy()
		return

	var final_damage := damage

	# Apply critical for sniper
	if special == "critical" and randf() < 0.25:
		final_damage *= 2.0
		_spawn_crit_effect(enemy.global_position)

	# Check physical resistance
	var is_physical := bullet_type in [GameData.BulletType.SHOT, GameData.BulletType.SNIPER_SHOT, GameData.BulletType.RAPID_SHOT]
	if is_physical:
		final_damage *= (1.0 - enemy_stats.physical_resist)

	# Determine effect type
	var effect_type := "none"
	match bullet_type:
		GameData.BulletType.FIRE_SHOT:
			effect_type = "burn"
		GameData.BulletType.ICE_SHOT:
			effect_type = "freeze"

	enemy.take_damage(final_damage, effect_type, not enemy_stats.effect_immune)

	_spawn_hit_effect()

	if destroy_bullet:
		_destroy()


func _spawn_hit_effect() -> void:
	var particles := GPUParticles2D.new()
	particles.position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 6

	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = bullet_size
	material.direction = Vector3(-direction.x, -direction.y, 0)
	material.spread = 60.0
	material.initial_velocity_min = 40.0
	material.initial_velocity_max = 80.0
	material.gravity = Vector3(0, 50, 0)
	material.scale_min = 2.0
	material.scale_max = 5.0
	material.color = bullet_color
	particles.process_material = material

	get_parent().add_child(particles)
	_auto_free(particles, 0.5)


func _spawn_splash_effect(pos: Vector2) -> void:
	var particles := GPUParticles2D.new()
	particles.position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 12

	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 30.0
	material.spread = 180.0
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 60.0
	material.gravity = Vector3(0, 100, 0)
	material.scale_min = 3.0
	material.scale_max = 8.0
	material.color = Color(0.3, 1.0, 0.3, 0.8)
	particles.process_material = material

	get_parent().add_child(particles)
	_auto_free(particles, 0.8)


func _spawn_chain_effect(from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 4.0
	line.default_color = Color(0.7, 0.5, 1.0, 0.9)
	get_parent().add_child(line)
	_auto_free(line, 0.15)


func _spawn_crit_effect(pos: Vector2) -> void:
	var label := Label.new()
	label.text = "CRIT!"
	label.position = pos - Vector2(20, 30)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.YELLOW)
	get_parent().add_child(label)
	_auto_free(label, 0.5)


func _spawn_dodge_effect(pos: Vector2) -> void:
	var label := Label.new()
	label.text = "DODGE"
	label.position = pos - Vector2(25, 30)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	get_parent().add_child(label)
	_auto_free(label, 0.4)


func _auto_free(node: Node, delay: float) -> void:
	var timer := Timer.new()
	timer.wait_time = delay
	timer.one_shot = true
	timer.timeout.connect(node.queue_free)
	node.add_child(timer)
	timer.start()


func _check_bounds() -> void:
	if position.x < -100 or position.x > GameData.VIEWPORT_WIDTH + 100:
		_destroy()
	if position.y < -100 or position.y > GameData.VIEWPORT_HEIGHT + 100:
		_destroy()


func _destroy() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	queue_free()


func _draw() -> void:
	if is_destroyed:
		return

	# Draw trail
	if has_trail and trail_points.size() > 1:
		for i in range(trail_points.size() - 1):
			var alpha := 1.0 - float(i) / float(trail_points.size())
			var width := bullet_size * alpha * 0.8
			var trail_color := Color(bullet_color, alpha * 0.5)
			var local_from := trail_points[i] - position
			var local_to := trail_points[i + 1] - position
			draw_line(local_from, local_to, trail_color, width)

	# Draw glow
	draw_circle(Vector2.ZERO, bullet_size * 2.0, glow_color)

	# Draw bullet based on type
	match bullet_type:
		GameData.BulletType.SHOT, GameData.BulletType.RAPID_SHOT:
			draw_circle(Vector2.ZERO, bullet_size, bullet_color)

		GameData.BulletType.SNIPER_SHOT:
			# Elongated bullet
			var points: PackedVector2Array = [
				Vector2(-bullet_size * 2, 0),
				Vector2(0, -bullet_size * 0.5),
				Vector2(bullet_size * 2, 0),
				Vector2(0, bullet_size * 0.5)
			]
			draw_colored_polygon(points, bullet_color)

		GameData.BulletType.FIRE_SHOT:
			# Fire effect with gradient
			draw_circle(Vector2.ZERO, bullet_size * 1.2, Color(1.0, 0.2, 0.0, 0.7))
			draw_circle(Vector2.ZERO, bullet_size, Color(1.0, 0.5, 0.1))
			draw_circle(Vector2.ZERO, bullet_size * 0.6, Color(1.0, 0.8, 0.3))
			draw_circle(Vector2.ZERO, bullet_size * 0.3, Color.WHITE)

		GameData.BulletType.ICE_SHOT:
			# Ice crystal effect
			draw_circle(Vector2.ZERO, bullet_size * 1.1, Color(0.3, 0.7, 1.0, 0.6))
			draw_circle(Vector2.ZERO, bullet_size, Color(0.5, 0.9, 1.0))
			# Crystal spikes
			for i in range(6):
				var angle := i * TAU / 6.0
				var spike_end := Vector2.from_angle(angle) * bullet_size * 1.5
				draw_line(Vector2.ZERO, spike_end, Color(0.8, 0.95, 1.0), 2.0)
			draw_circle(Vector2.ZERO, bullet_size * 0.4, Color.WHITE)

		GameData.BulletType.ACID_SHOT:
			# Acid blob with bubbles
			draw_circle(Vector2.ZERO, bullet_size, Color(0.2, 0.8, 0.2))
			draw_circle(Vector2(-bullet_size * 0.3, -bullet_size * 0.2), bullet_size * 0.3, Color(0.4, 1.0, 0.4))
			draw_circle(Vector2(bullet_size * 0.2, bullet_size * 0.3), bullet_size * 0.25, Color(0.5, 1.0, 0.5))
			draw_circle(Vector2.ZERO, bullet_size * 0.5, Color(0.6, 1.0, 0.6, 0.7))

		GameData.BulletType.LASER_BEAM:
			# Laser line
			draw_line(Vector2(-500, 0), Vector2(500, 0), Color(1.0, 0.0, 0.0, 0.3), bullet_size * 3)
			draw_line(Vector2(-500, 0), Vector2(500, 0), Color(1.0, 0.3, 0.3), bullet_size * 2)
			draw_line(Vector2(-500, 0), Vector2(500, 0), Color(1.0, 0.8, 0.8), bullet_size)
			draw_circle(Vector2.ZERO, bullet_size * 2, Color(1.0, 1.0, 1.0, 0.8))

		GameData.BulletType.TESLA_ARC:
			# Electric arc effect
			draw_circle(Vector2.ZERO, bullet_size * 1.5, Color(0.6, 0.3, 1.0, 0.4))
			draw_circle(Vector2.ZERO, bullet_size, Color(0.7, 0.5, 1.0))
			# Lightning bolts
			for i in range(4):
				var angle := i * TAU / 4.0 + randf() * 0.5
				var bolt_end := Vector2.from_angle(angle) * bullet_size * 2.0
				var mid := bolt_end * 0.5 + Vector2(randf_range(-5, 5), randf_range(-5, 5))
				draw_line(Vector2.ZERO, mid, Color(0.9, 0.7, 1.0), 2.0)
				draw_line(mid, bolt_end, Color(0.9, 0.7, 1.0), 2.0)
			draw_circle(Vector2.ZERO, bullet_size * 0.5, Color.WHITE)
