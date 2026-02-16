extends Node2D

@export var max_scale := 0.8
@export var lifetime := 0.4

func _ready():
	scale = Vector2.ZERO
	modulate.a = 0.8

	var tween := create_tween()

	tween.tween_property(
		self,
		"scale",
		Vector2(max_scale, max_scale),
		lifetime
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		lifetime
	)

	tween.tween_callback(queue_free)
