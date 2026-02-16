extends Area2D

@export var speed := 420.0
@export var amplitude := 30.0
@export var frequency := 4.0

var base_y := 0.0
var t := 0.0


func _ready() -> void:
	base_y = global_position.y
	$AnimatedSprite2D.play("fly")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	t += delta

	# Movimiento horizontal
	global_position.x -= speed * delta

	# Movimiento senoidal vertical
	global_position.y = base_y + sin(t * frequency) * amplitude

	# Limpiar cuando sale de cámara
	if global_position.x < -300:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.name == "Dino":
		call_deferred("set_monitoring", false)
		get_tree().call_group("game", "game_over")
