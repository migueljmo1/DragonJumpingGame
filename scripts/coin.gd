extends Area2D

@export var value := 1
@export var float_amplitude := 40.0
@export var float_speed := 6.0

var base_y := 0.0
var t := 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var col: CollisionShape2D = $CollisionShape2D

var popup_scene := preload("res://scenes/coin_popup.tscn")

func _ready() -> void:
	_set_visual()
	body_entered.connect(_on_body_entered)
	base_y = position.y

func _set_visual() -> void:
	match value:
		1:
			anim.play("gold")
		5:
			anim.play("blue")
		10:
			anim.play("purple")
		_:
			anim.play("gold")

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	# Avisar al juego
	get_tree().call_group("game", "add_coin", value)

	# Crear efectos ANTES de borrar
	_spawn_particles()

	var popup := popup_scene.instantiate()
	popup.global_position = global_position
	popup.setup("+" + str(value))
	get_tree().current_scene.add_child(popup)

	# Desactivar colisión para evitar dobles triggers
	col.call_deferred("set_disabled", true)
	set_deferred("monitoring", false)

	# Borrar DESPUÉS
	call_deferred("queue_free")

func _play_pickup_effect() -> void:
	var tween := create_tween()
	tween.tween_property(anim, "scale", Vector2(1.4, 1.4), 0.08)
	tween.tween_property(anim, "scale", Vector2.ZERO, 0.12)

func _process(delta: float) -> void:
	t += delta
	position.y = base_y + sin(t * float_speed) * float_amplitude
func _spawn_particles():
	var p := CPUParticles2D.new()
	p.top_level = true
	p.global_position = global_position
	p.one_shot = true
	p.emitting = true
	p.z_index = 1000

	# 🔥 MÁS PARTÍCULAS
	p.amount = 45

	# ⏱️ DURACIÓN
	p.lifetime = 0.4
	p.explosiveness = 0.95
	p.spread = 180.0

	# 🚀 VELOCIDAD (más energía)
	p.initial_velocity_min = 180.0
	p.initial_velocity_max = 320.0

	# 🌍 GRAVEDAD
	p.gravity = Vector2(0, 600)

	# 📏 TAMAÑO MÁS GRANDE
	p.scale_amount_min = 2.4
	p.scale_amount_max = 3.8

	# 🎨 COLOR SEGÚN VALOR
	match value:
		1:
			p.color = Color(1.0, 0.85, 0.2)   # dorado
		5:
			p.color = Color(0.4, 0.8, 1.0)    # azul
		10:
			p.color = Color(0.9, 0.4, 1.0)    # morado

	get_tree().current_scene.add_child(p)

	# 🧹 AUTODESTRUCCIÓN
	await get_tree().create_timer(p.lifetime + 0.1).timeout
	p.queue_free()
