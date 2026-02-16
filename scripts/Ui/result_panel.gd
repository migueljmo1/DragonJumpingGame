extends Control

signal retry_pressed
signal shop_pressed

@onready var board := $Board
@onready var distance_label := $Board/DistanceLabel
@onready var run_coins_label := $Board/RunCoinsLabel
@onready var best_score_label := $Board/BestScoreLabel
@onready var left_skin_preview := $Board/LeftSkinPreview
@onready var left_pet_preview := $Board/LeftPetPreview
@onready var retry_button := $Board/RetryButton
@onready var shop_button := $Board/ShopButton

@export var enter_offset := 700.0

var board_final_pos: Vector2
var retry_base_scale: Vector2
var shop_base_scale: Vector2
var buttons_locked := false

# =========================
# READY
# =========================
func _ready():
	retry_base_scale = retry_button.scale
	shop_base_scale = shop_button.scale

	board_final_pos = board.position
	hide()

	retry_button.pressed.connect(_on_retry_pressed)
	shop_button.pressed.connect(_on_shop_pressed)


# =========================
# MOSTRAR PANEL
# =========================
func show_panel(score: int, best_score: int, coins: int):
	buttons_locked = false
	retry_button.disabled = false
	shop_button.disabled = false

	show()

	# Posición inicial abajo
	board.position = board_final_pos + Vector2(0, enter_offset)

	var tween := create_tween()
	tween.tween_property(
		board,
		"position",
		board_final_pos,
		0.45
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Cuando termina el bounce:
	tween.tween_callback(func():
		animate_score(score, best_score, coins)
		animate_left_side()
	)
	await tween.finished

	play_button_glow(retry_button)
	await get_tree().create_timer(0.1).timeout
	play_button_glow(shop_button)


# =========================
# ANIMAR SCORE
# =========================
func animate_score(score: int, best_score: int, coins: int):
	var duration := 0.8

	var tween := create_tween()
	tween.tween_method(
		func(value):
			distance_label.text = str(int(value)) + " M",
		0.0,
		float(score),
		duration
	)

	run_coins_label.text = str(coins)

	if score >= best_score:
		best_score_label.text = "NEW BEST!"
		play_new_record_effect()
	else:
		best_score_label.text = str(best_score) + " M"

# =========================
# EFECTO NUEVO RÉCORD
# =========================
func play_new_record_effect():
	spawn_new_record_particles()

	var tween := create_tween()
	best_score_label.scale = Vector2.ONE

	tween.tween_property(best_score_label, "scale", Vector2(1.5, 1.5), 0.15)
	tween.tween_property(best_score_label, "scale", Vector2.ONE, 0.15)

# =========================
# ANIMAR LADO IZQUIERDO
# =========================
func animate_left_side():
	left_skin_preview.scale = Vector2.ZERO
	left_pet_preview.scale = Vector2.ZERO

	var tween := create_tween()

	tween.tween_property(
		left_skin_preview,
		"scale",
		Vector2.ONE,
		0.3
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_interval(0.1)

	tween.tween_property(
		left_pet_preview,
		"scale",
		Vector2.ONE,
		0.3
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# =========================
# OCULTAR PANEL
# =========================
func hide_panel():
	hide()

# =========================
# BOTONES
# =========================
func _on_retry_pressed():
	if buttons_locked:
		return

	buttons_locked = true
	retry_button.disabled = true
	shop_button.disabled = true

	var tween := create_tween()

	tween.tween_property(
		retry_button,
		"scale",
		retry_base_scale * 0.9,
		0.08
	)

	tween.tween_property(
		retry_button,
		"scale",
		retry_base_scale,
		0.08
	)

	await tween.finished
	emit_signal("retry_pressed")

func _on_shop_pressed():
	if buttons_locked:
		return

	buttons_locked = true
	retry_button.disabled = true
	shop_button.disabled = true

	var tween := create_tween()

	tween.tween_property(
		shop_button,
		"scale",
		shop_base_scale * 0.9,
		0.08
	)

	tween.tween_property(
		shop_button,
		"scale",
		shop_base_scale,
		0.08
	)

	await tween.finished
	emit_signal("shop_pressed")

func play_button_glow(button: Control):
	var original_modulate := button.modulate
	button.modulate = Color(1,1,1,0.0)

	var tween := create_tween()

	# Aparece
	tween.tween_property(
		button,
		"modulate:a",
		1.0,
		0.25
	)

	# Flash leve
	tween.tween_property(
		button,
		"modulate",
		Color(1.3,1.3,1.3,1),
		0.1
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		button,
		"modulate",
		original_modulate,
		0.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func spawn_new_record_particles():
	var particles := GPUParticles2D.new()
	var mat := ParticleProcessMaterial.new()

	# Configuración básica
	particles.amount = 50
	particles.lifetime = 0.7
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.process_material = mat

	# Material
	mat.gravity = Vector3.ZERO
	mat.initial_velocity_min = 200.0
	mat.initial_velocity_max = 350.0
	mat.angular_velocity_min = -6.0
	mat.angular_velocity_max = 6.0
	mat.scale_min = 4.0
	mat.scale_max = 8.0
	mat.spread = 180.0

	# Color dorado
	mat.color = Color(1.0, 0.85, 0.2)

	# Posición (detrás del texto)
	particles.position = best_score_label.position + Vector2(0, 20)

	$Board.add_child(particles)

	particles.emitting = true

	# Auto eliminar
	await get_tree().create_timer(1.0).timeout
	particles.queue_free()
