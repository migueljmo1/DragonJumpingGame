extends Node2D

@export var lifetime := 0.6

func _ready() -> void:
	top_level = true
	z_index = 50

	scale = Vector2(0.4, 0.4)
	modulate = Color(1, 1, 1, 0.7)

	var t := create_tween()
	t.tween_property(self, "scale", Vector2.ONE, lifetime)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	t.tween_property(self, "modulate:a", 0.0, lifetime)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	await get_tree().create_timer(lifetime).timeout
	queue_free()
