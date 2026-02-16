extends Area2D

@export var rotation_offset: float = PI

# Temblor leve
@export var wobble_amount: float = 2.0
@export var wobble_speed: float = 22.0

# Piso/cráter (main.gd setea estos valores)
@export var ground_y: float = 520.0
@export var crater_y: float = 520.0

# Explosión
@export var explosion_lifetime: float = 0.45

# Cráter
@export var crater_lifetime: float = 2.0

# Seguridad: vida máxima
@export var max_life: float = 8.0

var _velocity: Vector2 = Vector2.ZERO
var _active: bool = false
var _impacted: bool = false
var _t: float = 0.0
var _life: float = 0.0

var warning_scene := preload("res://scenes/meteorwarning.tscn")

func _ready() -> void:
	# ✅ Si en tu met.tscn hay notifiers/enablers que hacen queue_free, los desactivamos
	_disable_auto_visibility_kill()
	body_entered.connect(_on_body_entered)

func _disable_auto_visibility_kill() -> void:
	# Nombres típicos (por si los tienes con esos nombres)
	var names := [
		"VisibleOnScreenNotifier2D",
		"VisibleOnScreenEnabler2D",
		"VisibilityNotifier2D",
		"VisibilityEnabler2D"
	]

	for n in names:
		if has_node(n):
			get_node(n).queue_free()

	# También por si están con otro nombre, pero del tipo correcto
	for child in get_children():
		if child is VisibleOnScreenNotifier2D or child is VisibleOnScreenEnabler2D:
			child.queue_free()

func setup(spawn_pos: Vector2, target_pos: Vector2, fall_time_sec: float) -> void:
	global_position = spawn_pos

	var t = max(0.25, fall_time_sec)
	_velocity = (target_pos - spawn_pos) / t
	_active = true
	_impacted = false
	_t = 0.0
	_life = 0.0

	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("flying")

	rotation = _velocity.angle() + rotation_offset
	call_deferred("_spawn_warning", target_pos)

 
func _physics_process(delta: float) -> void:
	if not _active or _impacted:
		return

	_t += delta
	_life += delta

	# Seguridad: si por alguna razón vive demasiado, lo impactamos igual
	if _life > max_life:
		_force_impact()
		return

	# Movimiento
	global_position += _velocity * delta

	# Temblor perpendicular
	var perp := Vector2(-_velocity.y, _velocity.x).normalized()
	var wobble := sin(_t * wobble_speed) * wobble_amount
	global_position += perp * wobble * delta * 60.0

	# Rotación hacia dirección
	rotation = _velocity.angle() + rotation_offset

	# ✅ Impacto garantizado por Y (sin depender de raycast)
	if global_position.y >= ground_y:
		_force_impact()

func _force_impact() -> void:
	impact(Vector2(global_position.x, ground_y))

func impact(ground_hit: Vector2) -> void:
	if _impacted:
		return

	_impacted = true
	_active = false
	_vibrate_on_impact()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	# ✅ USA EL PUNTO REAL DEL IMPACTO (X e Y)
	var hit_x := ground_hit.x
	var hit_y := ground_hit.y

	# Explosión en el impacto real
	_spawn_explosion(Vector2(hit_x, hit_y))

	# Cráter en el impacto real (con tu offset visual)
	_spawn_crater(Vector2(hit_x, hit_y + 6.0))

	queue_free()

func _on_body_entered(body: Node) -> void:
	if body == null:
		return

	# ✅ SI TOCA AL JUGADOR → GAME OVER
	if body.is_in_group("player"):
		call_deferred("set_monitoring", false)
		get_tree().call_group("game", "game_over")

	var impact_x := global_position.x

	if body.has_node("RunCol"):
		impact_x = body.get_node("RunCol").global_position.x
	elif body.has_node("DuckCol"):
		impact_x = body.get_node("DuckCol").global_position.x
	elif body is Node2D:
		impact_x = body.global_position.x

	impact(Vector2(impact_x, ground_y))

func _spawn_explosion(pos: Vector2) -> void:
	var root := get_tree().current_scene
	if root == null:
		return

	var p := CPUParticles2D.new()
	p.top_level = true
	p.global_position = pos
	p.one_shot = true
	p.emitting = true

	p.amount = 45
	p.lifetime = explosion_lifetime
	p.explosiveness = 0.95
	p.spread = 180.0

	p.initial_velocity_min = 140.0
	p.initial_velocity_max = 320.0
	p.gravity = Vector2(0, 900)

	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2

	p.color = Color(1.0, 0.45, 0.05, 0.95)

	root.add_child(p)

	var t := get_tree().create_timer(explosion_lifetime + 0.15)
	t.timeout.connect(func():
		if is_instance_valid(p):
			p.queue_free()
	)

func _spawn_crater(pos: Vector2) -> void:
	var root := get_tree().current_scene
	if root == null:
		return

	var crater := Line2D.new()
	crater.top_level = true
	crater.global_position = pos
	crater.z_index = 5
	crater.width = 14.0
	crater.closed = true
	crater.joint_mode = Line2D.LINE_JOINT_ROUND
	crater.begin_cap_mode = Line2D.LINE_CAP_ROUND
	crater.end_cap_mode = Line2D.LINE_CAP_ROUND
	crater.default_color = Color(0.12, 0.08, 0.06, 0.85)

	var points := 20
	var rx := randf_range(22.0, 34.0)
	var ry := randf_range(10.0, 16.0)

	for i in points:
		var a := (TAU * float(i)) / float(points)
		var jitter := randf_range(0.85, 1.15)
		crater.add_point(Vector2(cos(a) * rx * jitter, sin(a) * ry * jitter))

	root.add_child(crater)

	var tween := root.create_tween()
	tween.tween_property(crater, "modulate:a", 0.0, crater_lifetime).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		if is_instance_valid(crater):
			crater.queue_free()
	)
func _spawn_warning(pos: Vector2) -> void:
	if not is_inside_tree():
		return
	
	var w := warning_scene.instantiate()
	w.global_position = Vector2(pos.x, ground_y)
	get_tree().root.add_child(w)
	
func _vibrate_on_impact():
	# Solo vibra en dispositivos que lo soportan (Android)
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(0.15)
