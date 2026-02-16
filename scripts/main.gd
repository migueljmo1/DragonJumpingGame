extends Node

@onready var dino := $Dino
@onready var cam := $Camera2D
@onready var coin_label := $HUD/RunUI/CoinLabel


# --- GROUND (DOBLE PISO) ---
@onready var ground_parent := $GroundParents
@onready var ground_a := $GroundParents/GroundA
@onready var ground_b := $GroundParents/GroundB
@export var ground_width := 1920.0

@onready var start_label := $HUD/MainMenuUI/StartLabel
@onready var score_label := $HUD/RunUI/ScoreLabel
@onready var high_score_label := $HUD/RunUI/HighScoreLabel

@onready var revive_panel := $HUD/RevivePanel2
@onready var results_panel := $HUD/ResultPanel

var menu_float_time := 0.0
@export var menu_float_strength := 6.0
@export var menu_float_speed := 1.2

@onready var logo := $HUD/MainMenuUI/Logo
var logo_base_y := 0.0
var logo_time := 0.0

# --- ESCENAS ---
var met_scene := preload("res://scenes/met.tscn")
var rino_scene := preload("res://scenes/rino.tscn")
var pterodactilo_scene := preload("res://scenes/pterodactilo.tscn")
var coin_scene := preload("res://scenes/coin.tscn")
var revive_ring_scene := preload("res://scenes/revive_ring.tscn")

# --- POSICIONES INICIALES ---
var DINO_START_POS: Vector2
var CAM_START_POS: Vector2
var GROUND_A_START_POS: Vector2
var GROUND_B_START_POS: Vector2

# --- ESTADOS ---
var game_running := false
var is_dead := false
var can_restart := false
var is_reviving := false

# --- SCORE ---
var score := 0
const SCORE_MODIFIER := 100
var high_score := 0

# --- COIN ---
var coins := 0
# --- MONEDAS DE LA RUN ---
var run_coins := 0

# --- DIFICULTAD ---
var difficulty := 0.0

# --- VELOCIDAD ---
var speed := 0.0
const START_SPEED := 320.0
const MAX_SPEED := 700.0

# --- SPAWN ---
var next_spawn_x := 0.0
const SPAWN_AHEAD := 900.0
const SPAWN_MIN_GAP := 900.0
const SPAWN_MAX_GAP := 1450.0

# --- METEORO ---
const METEOR_SPAWN_Y := -120.0

# --- PISO REAL ---
var meteor_floor_y := 0.0

# --- CÁMARA ---
const CAMERA_X_OFFSET := 450

# --- READY / GO ---
var spawn_delay_timer := 0.0
const SPAWN_DELAY := 2.0
var go_flash_done := false

# --- OBSTÁCULOS ---
enum ObstacleType { METEOR, RINO, PTERODACTILO }
var next_obstacle := ObstacleType.RINO

# --- CAMERA SHAKE ---
var shake_time := 0.0
var shake_strength := 0.0

# --- RESPAWN DELAY TRAS REVIVIR ---
@export var revive_spawn_delay := 1400.0

var waiting_for_decision := false
var menu_intro_playing := true

func _ready() -> void:
	logo_base_y = logo.position.y

	$HUD/MainMenuUI/Logo.scale = Vector2(0.8,0.8)
	var t := create_tween()
	t.tween_property($HUD/MainMenuUI/Logo, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK)

	results_panel.retry_pressed.connect(_on_retry_pressed)
	results_panel.shop_pressed.connect(_on_shop_pressed)

	SaveGame.load_game()

	high_score = SaveGame.high_score
	coins = SaveGame.coins

	update_coin_ui()
	update_high_score_ui()

	add_to_group("game")

	revive_panel.revive_selected.connect(_on_revive_selected)
	revive_panel.double_coins_selected.connect(_on_double_coins_selected)
	revive_panel.skip_selected.connect(_on_skip_selected)

	DINO_START_POS = dino.position
	CAM_START_POS = cam.position
	GROUND_A_START_POS = ground_a.position
	GROUND_B_START_POS = ground_b.position

	new_game()
	await get_tree().process_frame
	play_menu_intro()

func _on_revive_selected():
	revive_panel.hide()

	waiting_for_decision = false
	is_reviving = true

	# 1️⃣ Frenar mundo
	game_running = false

	# 2️⃣ Limpiar obstáculos
	clear_nearby_obstacles()

	# 3️⃣ Esperar 1 frame (CLAVE)
	await get_tree().process_frame

	# 4️⃣ Revivir dino
	dino.revive(meteor_floor_y)

	# 5️⃣ Feedback
	revive_slow_motion()
	camera_revive_zoom()
	spawn_revive_ring(dino.global_position + Vector2(0, 40))

	# 6️⃣ Reanudar mundo
	is_dead = false
	is_reviving = false
	game_running = true

	# 7️⃣ Retrasar spawn de enemigos
	next_spawn_x = cam.position.x + revive_spawn_delay


func _on_double_coins_selected():
	run_coins *= 2
	update_coin_ui()

	_finalize_run_coins()
	
func _finalize_run_coins():
	SaveGame.coins += run_coins
	SaveGame.save()

	waiting_for_decision = false
	can_restart = true

func _on_skip_selected():
	_finalize_run_coins()
	show_results()

func _on_retry_pressed():
	await play_retry_transition()
	new_game()

func play_retry_transition():
	var tween := create_tween()

	# Fade del panel
	tween.tween_property(results_panel, "modulate:a", 0.0, 0.25)

	# Pequeño zoom out de cámara
	tween.parallel().tween_property(
		cam,
		"zoom",
		Vector2(1.2, 1.2),
		0.25
	)

	await tween.finished

func _on_shop_pressed():
	print("Ir a tienda")

func double_run_coins():
	# Aquí luego duplicamos monedas de la run
	pass

func show_results_panel():
	print("RESULTADOS")

# ======================
# NUEVA PARTIDA
# ======================
func new_game() -> void:
	results_panel.modulate.a = 1.0
	cam.zoom = Vector2(1.15, 1.15)

	run_coins = 0
	update_coin_ui()

	is_dead = false
	can_restart = false
	game_running = false
	Engine.time_scale = 1.0

	score = 0
	speed = START_SPEED
	difficulty = 0.0

	dino.position = DINO_START_POS
	cam.position = CAM_START_POS
	ground_a.position = GROUND_A_START_POS
	ground_b.position = GROUND_B_START_POS
	
	if dino.has_method("reset_state"):
		dino.call("reset_state")


	if dino.has_method("set_input_enabled"):
		dino.call("set_input_enabled", false)

	cam.position.x = dino.position.x + CAMERA_X_OFFSET

	var col := ground_a.get_node("CollisionShape2D")
	var shape = col.shape
	meteor_floor_y = col.global_position.y - shape.extents.y

	for n in get_tree().get_nodes_in_group("obstacle"):
		n.queue_free()

	start_label.text = "PRESS TO PLAY"

	update_score_ui()
	update_high_score_ui()

	next_spawn_x = cam.position.x + SPAWN_AHEAD
	spawn_delay_timer = 0.0
	go_flash_done = false
# UI Estado menú
	$HUD/RunUI.hide()
	$HUD/MainMenuUI.show()

	start_label.text = "TOCA PARA COMENZAR"
	start_label.show()

	results_panel.hide_panel()
	revive_panel.hide()
	play_menu_intro()

func play_menu_intro():
	menu_intro_playing = true
	
	var logo := $HUD/MainMenuUI/Logo
	var start_label := $HUD/MainMenuUI/StartLabel
	
	# Estado inicial
	logo.scale = Vector2(0.8, 0.8)
	start_label.modulate.a = 0.0
	
	var tween := create_tween()
	tween.set_parallel(false)

	# Logo bounce entrada
	tween.tween_property(
		logo,
		"scale",
		Vector2(1.05, 1.05),
		0.25
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		logo,
		"scale",
		Vector2(1, 1),
		0.15
	)

	# Aparece texto
	tween.tween_property(
		start_label,
		"modulate:a",
		1.0,
		0.3
	)

	# 🔓 DESBLOQUEAR INPUT CUANDO TERMINE
	await tween.finished
	menu_intro_playing = false
# ======================
# INICIO REAL
# ======================
func start_game() -> void:

	game_running = true
	can_restart = false

	# UI
	$HUD/MainMenuUI.hide()
	$HUD/RunUI.show()

	if dino.has_method("set_input_enabled"):
		dino.call("set_input_enabled", true)

	if dino.has_method("suppress_jump_once"):
		dino.call("suppress_jump_once")

	spawn_delay_timer = SPAWN_DELAY
	next_spawn_x += SPAWN_MIN_GAP
# ======================
# GAME OVER
# ======================
func game_over() -> void:
	if is_dead:
		return

	is_dead = true
	game_running = false
	can_restart = false

	if dino.has_method("set_input_enabled"):
		dino.call("set_input_enabled", false)

	if dino.has_method("play_death_feedback"):
		dino.call("play_death_feedback")

	start_camera_shake(14.0, 0.3)

	Engine.time_scale = 0.15
	await get_tree().create_timer(0.12).timeout
	Engine.time_scale = 1.0

	for n in get_tree().get_nodes_in_group("obstacle"):
		n.queue_free()

	var current := int(score / float(SCORE_MODIFIER))
	if current > high_score:
		high_score = current
		update_high_score_ui()
		
	var final_score := get_display_score()
	if final_score > SaveGame.high_score:
		SaveGame.high_score = final_score
		SaveGame.save()


	high_score_label.text = "High Score: " + str(SaveGame.high_score)

	dino.velocity.x = 0
	can_restart = true
	waiting_for_decision = true

	# ⏳ Esperar a que se vea la muerte
	await get_tree().create_timer(0.5).timeout

	show_revive_panel()

	
func show_revive_panel():
	print("MOSTRANDO PANEL")
	revive_panel.show_panel()

# ======================
# INPUT
# ======================
func _input(event: InputEvent) -> void:
	# Si animación inicial del menú está corriendo
	if menu_intro_playing:
		return

	# Si está en revive o resultados → bloquear
	if waiting_for_decision or is_dead:
		return

	# Solo iniciar desde menú
	if not game_running:

		# Teclado
		if event.is_action_pressed("ui_accept"):
			start_game()
			return

		# Touch / Mouse
		if event is InputEventScreenTouch and event.pressed:
			if not _is_touch_on_ui(event.position):
				start_game()
			return

func _is_touch_on_ui(pos: Vector2) -> bool:
	var ui_nodes = get_tree().get_nodes_in_group("menu_button")

	for node in ui_nodes:
		if node is Control:
			if node.get_global_rect().has_point(pos):
				return true

	return false



# ======================
# LOOP PRINCIPAL
# ======================
func _process(delta: float) -> void:
	# ===== LOGO FLOAT =====
	if not game_running:
		logo_time += delta
		logo.position.y = logo_base_y + sin(logo_time * 2.0) * 6.0

	if shake_time > 0.0:
		shake_time -= delta
		cam.offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	else:
		cam.offset = Vector2.ZERO

# ===== MENU FLOAT =====
	if not game_running and not is_dead:
		menu_float_time += delta * menu_float_speed
		cam.offset.y = sin(menu_float_time) * menu_float_strength
		return

	# ===== GAME RUN =====
	if not game_running or is_reviving:
		return


	difficulty = clamp(float(score) / 5000.0, 0.0, 1.0)
	speed = lerp(START_SPEED, MAX_SPEED, difficulty)

	var dx := speed * delta
	dino.position.x += dx
	cam.position.x = dino.position.x + CAMERA_X_OFFSET

	score += int(dx)
	update_score_ui()
	update_ground()

	if spawn_delay_timer > 0.0:
		spawn_delay_timer -= delta
		start_label.text = "READY" if spawn_delay_timer > 0.5 else "GO!"
		start_label.show()

		if spawn_delay_timer <= 0.0 and not go_flash_done:
			go_flash_done = true
			start_label.hide()
		return

	if cam.position.x + SPAWN_AHEAD >= next_spawn_x:
		choose_next_obstacle()

		match next_obstacle:
			ObstacleType.METEOR:
				spawn_meteor()
			ObstacleType.RINO:
				spawn_rino()
			ObstacleType.PTERODACTILO:
				spawn_pterodactilo()

		next_spawn_x += randf_range(SPAWN_MIN_GAP, SPAWN_MAX_GAP)


# ======================
# DOBLE PISO
# ======================
func update_ground() -> void:
	var cam_left_x = cam.position.x - get_viewport().get_visible_rect().size.x * 0.5

	if cam_left_x > ground_a.position.x + ground_width:
		ground_a.position.x = ground_b.position.x + ground_width

	if cam_left_x > ground_b.position.x + ground_width:
		ground_b.position.x = ground_a.position.x + ground_width


# ======================
# ELECCIÓN DE OBSTÁCULO
# ======================
func choose_next_obstacle() -> void:
	var r := randf()

	if difficulty < 0.3:
		next_obstacle = ObstacleType.RINO
	elif difficulty < 0.6:
		next_obstacle = ObstacleType.PTERODACTILO if r < 0.5 else ObstacleType.RINO
	else:
		if r < 0.4:
			next_obstacle = ObstacleType.METEOR
		elif r < 0.7:
			next_obstacle = ObstacleType.PTERODACTILO
		else:
			next_obstacle = ObstacleType.RINO


# ======================
# SPAWN OBSTÁCULOS
# ======================
func spawn_meteor() -> void:
	var m := met_scene.instantiate()
	m.add_to_group("obstacle")

	var spawn_x = cam.position.x + SPAWN_AHEAD
	var spawn_pos := Vector2(spawn_x, METEOR_SPAWN_Y)

	var fall_t = lerp(1.6, 1.0, difficulty)
	var predicted_x = dino.global_position.x + speed * (fall_t * 0.6)
	var target_pos := Vector2(predicted_x, meteor_floor_y)

	m.call("setup", spawn_pos, target_pos, fall_t)
	m.ground_y = meteor_floor_y
	m.crater_y = meteor_floor_y
	add_child(m)


func spawn_rino() -> void:
	var r := rino_scene.instantiate()
	r.add_to_group("obstacle")

	r.global_position = Vector2(
		cam.position.x + SPAWN_AHEAD + 130,
		meteor_floor_y - 40
	)

	r.speed = lerp(420.0, 650.0, difficulty)
	r.game_active = true
	add_child(r)

	# 🪙 60% probabilidad de moneda (HIJA)
	if randf() < 0.8:
		var coin := coin_scene.instantiate()
		var roll := randf()
		if roll < 0.75:
			coin.value = 1
		elif roll < 0.95:
			coin.value = 5
		else:
			coin.value = 10
		coin.position = Vector2(0, -250) # local al rino
		r.add_child(coin)

func spawn_pterodactilo() -> void:
	var p := pterodactilo_scene.instantiate()
	p.add_to_group("obstacle")

	p.global_position = Vector2(
		cam.position.x + SPAWN_AHEAD + 150,
		meteor_floor_y - 300
	)

	p.speed = lerp(380.0, 540.0, difficulty)
	add_child(p)

	# 🪙 60% probabilidad de moneda (HIJA)
	if randf() < 0.8:
		var coin := coin_scene.instantiate()
		var roll := randf()
		if roll < 0.75:
			coin.value = 1
		elif roll < 0.95:
			coin.value = 5
		else:
			coin.value = 10
		coin.position = Vector2(0, 200) # debajo del pterodáctilo
		p.add_child(coin)

# ======================
# UTILIDADES
# ======================
func start_camera_shake(strength := 12.0, duration := 0.25):
	shake_strength = strength
	shake_time = duration


func update_score_ui() -> void:
	score_label.text = "SCORE: " + str(get_display_score())

func get_display_score() -> int:
	return int(score / SCORE_MODIFIER)

func update_high_score_ui() -> void:
	high_score_label.text = "High Score: " + str(high_score)

func spawn_coin(pos: Vector2) -> void:
	var c := coin_scene.instantiate()
	c.global_position = pos
	add_child(c)

func add_coin(amount: int) -> void:
	run_coins += amount
	update_coin_ui()

func update_coin_ui():
	coin_label.text = str(run_coins)

	# Mini punch
	var tween := create_tween()
	coin_label.scale = Vector2.ONE
	tween.tween_property(coin_label, "scale", Vector2(1.2, 1.2), 0.08)
	tween.tween_property(coin_label, "scale", Vector2.ONE, 0.08)

func clear_nearby_obstacles(radius := 500):
	for o in get_tree().get_nodes_in_group("obstacle"):
		if abs(o.global_position.x - dino.global_position.x) < radius:
			o.queue_free()

func camera_revive_zoom():
	var tween := create_tween()

	# Zoom IN fuerte
	tween.tween_property(
		cam,
		"zoom",
		Vector2(0.95, 0.95),
		0.12
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Volver al zoom normal del juego
	tween.tween_property(
		cam,
		"zoom",
		Vector2(1.15, 1.15),
		0.25
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
func revive_slow_motion():
	Engine.time_scale = 0.6

	await get_tree().create_timer(0.25).timeout

	Engine.time_scale = 1.0

func spawn_revive_ring(pos: Vector2):
	var ring := revive_ring_scene.instantiate()
	ring.global_position = pos
	add_child(ring)

func show_results():
	$HUD/RunUI.hide()
	$HUD/MainMenuUI.hide()

	results_panel.show_panel(
		get_display_score(),
		SaveGame.high_score,
		run_coins
	)
