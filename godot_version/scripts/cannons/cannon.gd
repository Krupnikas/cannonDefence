extends Node2D
class_name Cannon
## Base Cannon Class - All cannon types inherit from this

# Cannon properties
var cannon_type: int = GameData.CannonType.GUN
var grid_position: Vector2i = Vector2i.ZERO
var damage: float = 10.0
var fire_rate: float = 1.0
var attack_range: float = 300.0
var bullet_type: int = GameData.BulletType.SHOT
var cannon_color: Color = Color.GRAY

# State
var fire_cooldown: float = 0.0
var current_target: Node2D = null
var current_angle: float = 0.0

# References
var bullet_layer: Node2D = null
var bullet_scene: PackedScene = preload("res://scenes/bullets/bullet.tscn")

# Visual elements
var body_radius: float = 40.0
var barrel_length: float = 50.0
var barrel_width: float = 16.0


func init(type: int, bullets_parent: Node2D) -> void:
	cannon_type = type
	bullet_layer = bullets_parent

	var stats: Dictionary = GameData.CANNON_STATS[cannon_type]
	damage = stats.damage
	fire_rate = stats.fire_rate
	attack_range = stats.range
	bullet_type = stats.bullet_type
	cannon_color = stats.color

	# Adjust visual size based on type
	match cannon_type:
		GameData.CannonType.GUN:
			body_radius = 35.0
			barrel_length = 45.0
			barrel_width = 14.0
		GameData.CannonType.BIG_GUN:
			body_radius = 45.0
			barrel_length = 55.0
			barrel_width = 18.0
		GameData.CannonType.MONSTER_GUN:
			body_radius = 60.0
			barrel_length = 70.0
			barrel_width = 24.0
		GameData.CannonType.FIRE_GUN:
			body_radius = 40.0
			barrel_length = 50.0
			barrel_width = 16.0
		GameData.CannonType.PLASMA_GUN:
			body_radius = 42.0
			barrel_length = 55.0
			barrel_width = 18.0

	queue_redraw()


func _process(delta: float) -> void:
	if GameData.is_game_over or GameData.is_paused:
		return

	fire_cooldown = max(0.0, fire_cooldown - delta)

	_find_target()
	_update_rotation(delta)
	_try_fire()


func _find_target() -> void:
	var game := get_parent().get_parent() as Node2D
	if game and game.has_method("get_closest_enemy"):
		current_target = game.get_closest_enemy(global_position, attack_range)


func _update_rotation(delta: float) -> void:
	if current_target and is_instance_valid(current_target):
		var target_angle := global_position.angle_to_point(current_target.global_position) + PI
		var angle_diff := wrapf(target_angle - current_angle, -PI, PI)
		current_angle += angle_diff * min(1.0, delta * 5.0)  # Smooth rotation
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

	var bullet := bullet_scene.instantiate()
	bullet.init(bullet_type, damage, current_target)

	# Spawn bullet at barrel tip
	var barrel_tip := global_position + Vector2.from_angle(current_angle) * barrel_length
	bullet.position = barrel_tip
	bullet.rotation = current_angle

	bullet_layer.add_child(bullet)


func _draw() -> void:
	# Draw range indicator (faint)
	draw_arc(Vector2.ZERO, attack_range, 0, TAU, 64, Color(cannon_color, 0.1), 2.0)

	# Draw body (circle)
	draw_circle(Vector2.ZERO, body_radius, cannon_color)
	draw_arc(Vector2.ZERO, body_radius, 0, TAU, 32, cannon_color.darkened(0.3), 3.0)

	# Draw barrel (rectangle rotated to current_angle)
	var barrel_offset := Vector2.from_angle(current_angle) * (body_radius * 0.5)
	var barrel_end := Vector2.from_angle(current_angle) * barrel_length
	var perp := Vector2.from_angle(current_angle + PI/2) * (barrel_width / 2.0)

	var barrel_points: PackedVector2Array = [
		barrel_offset + perp,
		barrel_offset - perp,
		barrel_end - perp,
		barrel_end + perp
	]

	var barrel_color := cannon_color.darkened(0.2)
	draw_colored_polygon(barrel_points, barrel_color)
	draw_polyline(barrel_points + PackedVector2Array([barrel_points[0]]), cannon_color.darkened(0.4), 2.0)

	# Draw barrel tip highlight
	draw_circle(barrel_end, barrel_width * 0.4, cannon_color.lightened(0.2))

	# Draw center circle
	draw_circle(Vector2.ZERO, body_radius * 0.3, cannon_color.lightened(0.1))
