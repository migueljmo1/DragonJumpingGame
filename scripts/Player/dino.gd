extends CharacterBody2D

# --- Física ---
@export var gravity := 4200.0
@export var fast_fall_multiplier := 2.8
@export var jump_speed := -2000.0

# --- Duck tuning ---
@export var duck_min_time := 0.18
var duck_timer := 0.0
var is_ducking := false
var block_duck_until_release := false

# --- Control ---
var _input_enabled := false
var _suppress_jump_once := false

var is_dead := false
var death_push_speed := -500


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled


func suppress_jump_once() -> void:
	_suppress_jump_once = true


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.y += gravity * delta
		move_and_slide()
		return


	# =========================
	# GRAVEDAD + FAST FALL
	# =========================
	var grav := gravity

	# Fast fall SOLO en el aire
	if not is_on_floor() and Input.is_action_pressed("duck"):
		grav *= fast_fall_multiplier
		block_duck_until_release = true

	velocity.y += grav * delta

	# =========================
	# SIN INPUT
	# =========================
	if not _input_enabled:
		_reset_duck()
		block_duck_until_release = false
		_play_idle()
		move_and_slide()
		return

	# =========================
	# EN EL SUELO
	# =========================
	if is_on_floor():
		velocity.y = 0.0

		# Si ya soltó duck, desbloqueamos
		if not Input.is_action_pressed("duck"):
			block_duck_until_release = false

		if duck_timer > 0.0:
			duck_timer -= delta

		# 🔥 SALTO SIEMPRE PRIORIDAD
		if Input.is_action_just_pressed("jump") and not _suppress_jump_once:
			_reset_duck()
			velocity.y = jump_speed
			_play_jump()

		elif _suppress_jump_once:
			_suppress_jump_once = false
			_reset_duck()
			_play_run()

		# Duck SOLO si no está bloqueado
		elif Input.is_action_pressed("duck") and not block_duck_until_release:
			if not is_ducking:
				is_ducking = true
				duck_timer = duck_min_time
			_play_duck()

		elif is_ducking and duck_timer > 0.0:
			_play_duck()

		elif is_ducking:
			_reset_duck()
			_play_run()

		else:
			_play_run()


	# =========================
	# EN EL AIRE
	# =========================
	else:
		_reset_duck()
		_play_jump()


	move_and_slide()


# =========================
# HELPERS
# =========================
func _reset_duck():
	is_ducking = false
	duck_timer = 0.0


func _play_idle():
	$AnimatedSprite2D.play("idle")
	$RunCol.disabled = false
	$DuckCol.disabled = true


func _play_run():
	$AnimatedSprite2D.play("run")
	$RunCol.disabled = false
	$DuckCol.disabled = true


func _play_duck():
	$AnimatedSprite2D.play("duck")
	$RunCol.disabled = true
	$DuckCol.disabled = false


func _play_jump():
	$AnimatedSprite2D.play("jump")
	$RunCol.disabled = false
	$DuckCol.disabled = true

func play_death_feedback():
	if is_dead:
		return

	is_dead = true
	_input_enabled = false

	# Empuje hacia delante
	velocity.x = death_push_speed

	# Si estaba en el aire, que CAIGA
	if velocity.y < 0:
		velocity.y = 0

	# Colisiones apagadas
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)

	# Animación
	$AnimatedSprite2D.play("death")

func reset_state():
	is_dead = false
	is_ducking = false
	duck_timer = 0.0
	block_duck_until_release = false
	_suppress_jump_once = false

	velocity = Vector2.ZERO

	# Colisiones correctas
	if has_node("RunCol"):
		$RunCol.disabled = false
	if has_node("DuckCol"):
		$DuckCol.disabled = true

	$AnimatedSprite2D.play("run")


func apply_hit_impulse(from_x: float, force := 800.0):
	# Empuja SIEMPRE hacia delante
	if global_position.x < from_x:
		velocity.x = force
	else:
		velocity.x = -force

	# Pequeña caída
	if velocity.y < 0:
		velocity.y = 0
		
func revive(floor_y: float):
	reset_state()

	# 📍 Pegarlo bien al piso
	global_position.y = floor_y - 20

	velocity = Vector2.ZERO
	move_and_slide()  # fuerza estado "en el suelo"

	set_input_enabled(false)

	play_revive_feedback()

	set_invincible(1.2)


var invincible := false

func set_invincible(time: float):
	invincible = true
	modulate = Color(1, 1, 1, 0.5)

	var t := create_tween()
	t.tween_interval(time)
	t.tween_callback(func():
		invincible = false
		modulate = Color(1, 1, 1, 1)
	)
func play_revive_feedback():
	# 🔒 Bloquear input brevemente
	set_input_enabled(false)

	# ⬆️ Salto corto pero visible
	velocity.y = -700

	# 🎞️ Forzar animación de salto
	$AnimatedSprite2D.play("jump")

	# ✨ Flash fuerte
	modulate = Color(1, 1, 1, 1)

	var tween := create_tween()

	tween.tween_property(
		self,
		"modulate",
		Color(1.3, 1.3, 1.3, 1),
		0.25
	)
	tween.tween_property(
		self,
		"modulate",
		Color(1, 1, 1, 0.4),
		0.1
	)
	tween.tween_property(
		self,
		"modulate",
		Color(1, 1, 1, 1),
		0.12
	)

	# 🔓 Devolver control
	tween.tween_callback(func():
		set_input_enabled(true)
	)
