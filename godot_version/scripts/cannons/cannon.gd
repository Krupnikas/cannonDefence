extends Node2D
class_name Cannon
## Cannon Class - With special effects for each type

# Cannon properties
var cannon_type: int = GameData.CannonType.GUN
var grid_position: Vector2i = Vector2i.ZERO
var damage: float = 10.0
var fire_rate: float = 1.0
var attack_range: float = 300.0
var bullet_type: int = GameData.BulletType.SHOT
var cannon_color: Color = Color.GRAY
var special: String = "none"

# HP System
var max_hp: float = 100.0
var hp: float = 100.0
var is_destroyed: bool = false

# Miner properties
var is_miner: bool = false
var coin_rate: float = 0.0
var coin_accumulator: float = 0.0

# State
var fire_cooldown: float = 0.0
var current_target: Node2D = null
var current_angle: float = 0.0

# References
var bullet_layer: Node2D = null
var game_ref: Node2D = null
var bullet_scene: PackedScene = preload("res://scenes/bullets/bullet.tscn")

# Visual elements
var body_radius: float = 40.0
var barrel_length: float = 50.0
var barrel_width: float = 16.0

# Signals
signal destroyed


func init(type: int, bullets_parent: Node2D, game: Node2D = null) -> void:
	cannon_type = type
	bullet_layer = bullets_parent
	game_ref = game

	var stats: Dictionary = GameData.CANNON_STATS[cannon_type]
	damage = stats.damage
	fire_rate = stats.fire_rate
	attack_range = stats.range
	bullet_type = stats.get("bullet_type", -1)
	cannon_color = stats.color
	special = stats.special

	# HP system
	max_hp = stats.get("hp", 100.0)
	hp = max_hp

	# Miner setup
	is_miner = (special == "miner")
	if is_miner:
		coin_rate = stats.get("coin_rate", 2.0)

	# Adjust visual size based on type
	match cannon_type:
		GameData.CannonType.GUN:
			body_radius = 32.0
			barrel_length = 42.0
			barrel_width = 12.0
		GameData.CannonType.SNIPER:
			body_radius = 28.0
			barrel_length = 60.0
			barrel_width = 8.0
		GameData.CannonType.RAPID:
			body_radius = 30.0
			barrel_length = 35.0
			barrel_width = 10.0
		GameData.CannonType.FIRE:
			body_radius = 34.0
			barrel_length = 40.0
			barrel_width = 14.0
		GameData.CannonType.ICE:
			body_radius = 34.0
			barrel_length = 42.0
			barrel_width = 14.0
		GameData.CannonType.ACID:
			body_radius = 36.0
			barrel_length = 38.0
			barrel_width = 16.0
		GameData.CannonType.LASER:
			body_radius = 30.0
			barrel_length = 55.0
			barrel_width = 6.0
		GameData.CannonType.TESLA:
			body_radius = 38.0
			barrel_length = 30.0
			barrel_width = 18.0
		GameData.CannonType.MINER:
			body_radius = 36.0
			barrel_length = 0.0  # No barrel
			barrel_width = 0.0

	queue_redraw()


func _process(delta: float) -> void:
	if is_destroyed or GameData.is_game_over or GameData.is_paused or GameData.is_victory:
		return

	# Miner generates coins instead of attacking
	if is_miner:
		_generate_coins(delta)
		queue_redraw()
		return

	fire_cooldown = max(0.0, fire_cooldown - delta)

	_find_target()
	_update_rotation(delta)
	_try_fire()


func _generate_coins(delta: float) -> void:
	coin_accumulator += coin_rate * delta
	if coin_accumulator >= 1.0:
		var coins_to_add := int(coin_accumulator)
		coin_accumulator -= coins_to_add
		GameData.add_money(coins_to_add)
		_spawn_coin_effect()


func _spawn_coin_effect() -> void:
	var label := Label.new()
	label.text = "+$"
	label.position = global_position - Vector2(15, 50)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.GOLD)
	get_parent().add_child(label)

	# Fade out and move up
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 30, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)


func take_damage(amount: float) -> void:
	if is_destroyed:
		return

	# Feature flag: cannon HP disabled
	if not Settings.ENABLE_CANNON_HP:
		return

	# Debug: invincible cannons
	if Settings.DEBUG_INVINCIBLE_CANNONS:
		return

	hp -= amount
	queue_redraw()

	if hp <= 0:
		hp = 0
		_die()


func _die() -> void:
	if is_destroyed:
		return

	is_destroyed = true
	emit_signal("destroyed")
	_spawn_destroy_effect()
	queue_free()


func _spawn_destroy_effect() -> void:
	var particles := GPUParticles2D.new()
	particles.position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 15

	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = body_radius
	material.direction = Vector3(0, -1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 80.0
	material.initial_velocity_max = 150.0
	material.gravity = Vector3(0, 300, 0)
	material.scale_min = 5.0
	material.scale_max = 10.0
	material.color = cannon_color
	particles.process_material = material

	get_parent().add_child(particles)

	var timer := Timer.new()
	timer.wait_time = 1.5
	timer.one_shot = true
	timer.timeout.connect(particles.queue_free)
	particles.add_child(timer)
	timer.start()


func _find_target() -> void:
	var game: Node2D = game_ref
	if game == null:
		game = get_parent().get_parent() as Node2D
	if game and game.has_method("get_closest_enemy"):
		current_target = game.get_closest_enemy(global_position, attack_range)


func _update_rotation(delta: float) -> void:
	if current_target and is_instance_valid(current_target):
		var target_angle := global_position.angle_to_point(current_target.global_position) + PI
		var angle_diff := wrapf(target_angle - current_angle, -PI, PI)
		current_angle += angle_diff * min(1.0, delta * 5.0)
		queue_redraw()


func _try_fire() -> void:
	if fire_cooldown > 0.0:
		return

	if current_target and is_instance_valid(current_target) and not current_target.is_dead:
		_fire()
		fire_cooldown = 1.0 / fire_rate


func _fire() -> void:
	if bullet_layer == null:
		return

	var barrel_tip := global_position + Vector2.from_angle(current_angle) * barrel_length

	var bullet := bullet_scene.instantiate()
	bullet.init(bullet_type, damage, current_target, barrel_tip, special)
	bullet.position = barrel_tip
	bullet.rotation = current_angle

	bullet_layer.add_child(bullet)


func get_sell_value() -> int:
	var stats: Dictionary = GameData.CANNON_STATS[cannon_type]
	return stats.sell_value


func _draw() -> void:
	if is_destroyed:
		return

	# Range indicator (not for miner)
	if not is_miner and attack_range > 0:
		draw_arc(Vector2.ZERO, attack_range, 0, TAU, 64, Color(cannon_color, 0.08), 1.5)

	# Base/platform
	draw_circle(Vector2.ZERO, body_radius + 4, Color(0.15, 0.15, 0.15))

	# Body
	draw_circle(Vector2.ZERO, body_radius, cannon_color)
	draw_arc(Vector2.ZERO, body_radius, 0, TAU, 32, cannon_color.darkened(0.3), 2.0)

	# Miner-specific visuals
	if is_miner:
		_draw_miner()
	else:
		_draw_barrel()

	# HP bar (if damaged)
	if hp < max_hp:
		_draw_hp_bar()


func _draw_barrel() -> void:
	if barrel_length <= 0:
		return

	var barrel_offset := Vector2.from_angle(current_angle) * (body_radius * 0.5)
	var barrel_end := Vector2.from_angle(current_angle) * barrel_length
	var perp := Vector2.from_angle(current_angle + PI/2) * (barrel_width / 2.0)

	var barrel_points: PackedVector2Array = [
		barrel_offset + perp,
		barrel_offset - perp,
		barrel_end - perp,
		barrel_end + perp
	]

	draw_colored_polygon(barrel_points, cannon_color.darkened(0.2))
	draw_polyline(barrel_points + PackedVector2Array([barrel_points[0]]), cannon_color.darkened(0.4), 1.5)

	# Barrel tip
	draw_circle(barrel_end, barrel_width * 0.4, cannon_color.lightened(0.2))

	# Center detail
	draw_circle(Vector2.ZERO, body_radius * 0.3, cannon_color.lightened(0.1))

	# Type-specific details
	match cannon_type:
		GameData.CannonType.FIRE:
			draw_circle(Vector2.ZERO, body_radius * 0.2, Color.ORANGE)
		GameData.CannonType.ICE:
			draw_circle(Vector2.ZERO, body_radius * 0.2, Color.CYAN)
		GameData.CannonType.ACID:
			draw_circle(Vector2.ZERO, body_radius * 0.2, Color.GREEN)
		GameData.CannonType.LASER:
			var barrel_end_pos := Vector2.from_angle(current_angle) * barrel_length
			draw_circle(barrel_end_pos, barrel_width * 0.6, Color(1, 0.2, 0.2, 0.5))
		GameData.CannonType.TESLA:
			for i in range(3):
				var angle := i * TAU / 3.0
				var pos := Vector2.from_angle(angle) * body_radius * 0.5
				draw_circle(pos, 4, Color(0.6, 0.4, 1.0))


func _draw_miner() -> void:
	# Animated pickaxe/mining symbol
	var time := Time.get_ticks_msec() / 1000.0
	var swing := sin(time * 3.0) * 0.3

	# Center coin symbol
	draw_circle(Vector2.ZERO, body_radius * 0.4, Color.GOLD)
	draw_arc(Vector2.ZERO, body_radius * 0.4, 0, TAU, 16, Color.GOLD.darkened(0.3), 2.0)

	# $ symbol in center
	var font_size := int(body_radius * 0.4)
	# Draw simple $ using lines
	draw_line(Vector2(-5, -8), Vector2(5, -8), Color.GOLD.darkened(0.4), 2.0)
	draw_line(Vector2(-5, 0), Vector2(5, 0), Color.GOLD.darkened(0.4), 2.0)
	draw_line(Vector2(-5, 8), Vector2(5, 8), Color.GOLD.darkened(0.4), 2.0)
	draw_line(Vector2(0, -12), Vector2(0, 12), Color.GOLD.darkened(0.4), 2.0)

	# Mining sparks (animated)
	for i in range(4):
		var angle := i * TAU / 4.0 + time * 2.0
		var dist := body_radius * 0.7 + sin(time * 4.0 + i) * 5.0
		var pos := Vector2.from_angle(angle) * dist
		draw_circle(pos, 3.0, Color.GOLD.lightened(0.3))


func _draw_hp_bar() -> void:
	var bar_width := body_radius * 2.0
	var bar_height := 6.0
	var bar_y := -body_radius - 16.0

	# Background
	draw_rect(Rect2(-bar_width/2, bar_y, bar_width, bar_height), Color(0.2, 0.1, 0.1))

	# HP fill
	var hp_ratio := hp / max_hp
	var fill_color: Color
	if hp_ratio > 0.6:
		fill_color = Color(0.2, 0.8, 0.2)
	elif hp_ratio > 0.3:
		fill_color = Color(0.9, 0.8, 0.2)
	else:
		fill_color = Color(0.9, 0.2, 0.2)

	draw_rect(Rect2(-bar_width/2, bar_y, bar_width * hp_ratio, bar_height), fill_color)
