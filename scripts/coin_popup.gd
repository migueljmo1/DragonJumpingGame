extends Node2D

@export var float_distance := 40.0
@export var lifetime := 0.6

func setup(text: String):
	$Label.text = text

	match text:
		"+1":
			$Label.modulate = Color(1.0, 0.85, 0.2)
		"+5":
			$Label.modulate = Color(0.4, 0.8, 1.0)
		"+10":
			$Label.modulate = Color(0.9, 0.4, 1.0)
		_:
			$Label.modulate = Color.WHITE

	var end_pos = position + Vector2(0, -float_distance)

	var tween := create_tween()
	$Label.scale = Vector2.ONE * 0.8

	tween.tween_property($Label, "scale", Vector2.ONE, 0.12)
	tween.tween_property(self, "position", end_pos, lifetime)
	tween.tween_property(self, "modulate:a", 0.0, lifetime)
	tween.tween_callback(queue_free)
