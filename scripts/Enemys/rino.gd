extends CharacterBody2D

@export var speed := 500.0
@export var gravity := 1200.0

var game_active := false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	anim.play("run")
	hitbox.body_entered.connect(_on_hitbox_body_entered)


func _physics_process(delta: float) -> void:
	if not game_active:
		return

	# Gravedad
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	# Movimiento horizontal
	velocity.x = -speed

	move_and_slide()

	# Destruir si sale de pantalla
	if global_position.x < -300:
		queue_free()


func _on_hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		get_tree().call_group("game", "game_over")
