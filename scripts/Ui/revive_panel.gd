extends Control

signal revive_selected
signal double_coins_selected
signal skip_selected

@onready var board := $Board
@onready var revive_slot := $Board/CardContainer/ReviveSlot
@onready var coin_slot := $Board/CardContainer/CoinSlot
@onready var revive_card := revive_slot.get_node("ReviveCard")
@onready var coin_card := coin_slot.get_node("CoinCard")
@onready var watch_ad_button: Button = $Board/WatchAdButton
@onready var skip_button: Button = $Board/SkipButton

@export var enter_offset := 600.0
@export var card_pop_delay := 0.2

var board_final_pos: Vector2


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

	board_final_pos = board.position

	# 🔒 Estado inicial limpio
	revive_slot.visible = false
	coin_slot.visible = false
	revive_card.disabled = true
	coin_card.disabled = true


func show_panel():
	print("SHOW PANEL LLAMADO")

	show()

	# Posición inicial del board
	board.position = board_final_pos + Vector2(0, enter_offset)

	# 🔒 Cartas ocultas SIEMPRE aquí
	watch_ad_button.visible = true
	skip_button.visible = true
	revive_slot.visible = false
	coin_slot.visible = false
	revive_card.disabled = true
	coin_card.disabled = true
	
	board.position = board_final_pos + Vector2(0, enter_offset)
	
	var tween := create_tween()
	tween.tween_property(
		board,
		"position",
		board_final_pos,
		0.45
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _show_cards():
	print("MOSTRANDO CARTAS")

	# Mostrar ahora sí
	revive_slot.visible = true
	coin_slot.visible = true

	revive_slot.scale = Vector2.ZERO
	coin_slot.scale = Vector2.ZERO

	var tween := create_tween()

	tween.tween_property(
		revive_slot,
		"scale",
		Vector2.ONE,
		0.25
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_interval(card_pop_delay)

	tween.tween_property(
		coin_slot,
		"scale",
		Vector2.ONE,
		0.25
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		revive_card.disabled = false
		coin_card.disabled = false
	)

func _on_revive_card_pressed() -> void:
	print("REVIVE CARD PRESSED")

	hide()
	emit_signal("revive_selected")


func _on_watch_ad_button_pressed() -> void:
	print("WATCH AD PRESSED")
	watch_ad_button.visible = false
	skip_button.visible = false
	# Aquí luego irá el anuncio real
	_show_cards()


func _on_coin_card_pressed() -> void:
	hide()
	emit_signal("double_coins_selected")


func _on_skip_button_pressed() -> void:
	watch_ad_button.visible = false
	skip_button.visible = false
	hide()
	get_tree().paused = false
	emit_signal("skip_selected")
