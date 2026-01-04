extends Node2D
class_name Bullet
## Base Bullet Class - All bullet types inherit from this

# Bullet properties
var bullet_type: int = GameData.BulletType.SHOT
var damage: float = 10.0
var speed: float = 400.0
var bullet_size: float = 8.0
var bullet_color: Color = Color.DARK_GRAY

# Movement
var target: Node2D = null
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 5.0

# State
var is_destroyed: bool = false


func init(type: int, dmg: float, target_enemy: Node2D) -> void:
	bullet_type = type
	damage = dmg
	target = target_enemy

	var stats: Dictionary = GameData.BULLET_STATS[bullet_type]
	speed = stats.speed
	bullet_size = stats.size
	bullet_color = stats.color

	if target and is_instance_valid(target):
		direction = global_position.direction_to(target.global_position)
		rotation = direction.angle()

	queue_redraw()


func _process(delta: float) -> void:
	if is_destroyed or GameData.is_game_over or GameData.is_paused:
		return

	lifetime -= delta
	if lifetime <= 0:
		_destroy()
		return

	_move(delta)
	_check_collision()
	_check_bounds()


func _move(delta: float) -> void:
	# Homing behavior for plasma shots
	if bullet_type == GameData.BulletType.PLASMA_SHOT and target and is_instance_valid(target) and not target.is_dead:
		var target_dir := global_position.direction_to(target.global_position)
		direction = direction.lerp(target_dir, delta * 3.0).normalized()
		rotation = direction.angle()

	position += direction * speed * delta
	queue_redraw()


func _check_collision() -> void:
	# Check if we hit any enemy
	var enemies := get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_dead:
			continue

		var dist := global_position.distance_to(enemy.global_position)
		if dist < bullet_size + enemy.body_radius:
			_hit_enemy(enemy)
			return


func _hit_enemy(enemy: Node2D) -> void:
	if enemy.has_method("take_damage"):
		var final_damage := damage

		# Fire shots do burn damage (extra damage over time simulation)
		if bullet_type == GameData.BulletType.FIRE_SHOT:
			final_damage *= 1.2

		enemy.take_damage(final_damage)

	_spawn_hit_effect()
	_destroy()


func _spawn_hit_effect() -> void:
	# Create simple hit particle
	var particles := GPUParticles2D.new()
	particles.position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 4

	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = bullet_size
	material.direction = Vector3(-direction.x, -direction.y, 0)
	material.spread = 45.0
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.gravity = Vector3(0, 100, 0)
	material.scale_min = 2.0
	material.scale_max = 4.0
	material.color = bullet_color
	particles.process_material = material

	get_parent().add_child(particles)

	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.timeout.connect(particles.queue_free)
	particles.add_child(timer)
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

	match bullet_type:
		GameData.BulletType.SHOT:
			# Simple circle
			draw_circle(Vector2.ZERO, bullet_size, bullet_color)
		GameData.BulletType.BIG_SHOT:
			# Larger circle with outline
			draw_circle(Vector2.ZERO, bullet_size, bullet_color)
			draw_arc(Vector2.ZERO, bullet_size, 0, TAU, 16, bullet_color.darkened(0.3), 2.0)
		GameData.BulletType.MONSTER_SHOT:
			# Heavy shot with trail
			draw_circle(Vector2.ZERO, bullet_size, bullet_color)
			draw_circle(Vector2(-bullet_size * 0.5, 0).rotated(rotation - global_rotation), bullet_size * 0.7, Color(bullet_color, 0.6))
		GameData.BulletType.FIRE_SHOT:
			# Fire effect
			draw_circle(Vector2.ZERO, bullet_size, Color.ORANGE)
			draw_circle(Vector2.ZERO, bullet_size * 0.6, Color.YELLOW)
			draw_circle(Vector2.ZERO, bullet_size * 0.3, Color.WHITE)
		GameData.BulletType.PLASMA_SHOT:
			# Glowing plasma
			draw_circle(Vector2.ZERO, bullet_size * 1.3, Color(bullet_color, 0.3))
			draw_circle(Vector2.ZERO, bullet_size, bullet_color)
			draw_circle(Vector2.ZERO, bullet_size * 0.5, Color.WHITE)
