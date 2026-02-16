extends Node

@export var min_swipe_px: float = 50.0
@export var duck_hold_time: float = 0.5

var _start_pos: Vector2
var _tracking := false

var _duck_timer: float = 0.0
var _duck_holding: bool = false

func _process(delta: float) -> void:
	if _duck_holding:
		_duck_timer -= delta
		if _duck_timer <= 0.0:
			_end_duck()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_tracking = true
			_start_pos = event.position
		else:
			_tracking = false
			# NO soltamos duck aquí: se suelta por timer o por jump (cancelación)

	elif event is InputEventScreenDrag and _tracking:
		var delta_vec = event.position - _start_pos

		if abs(delta_vec.y) >= min_swipe_px and abs(delta_vec.y) > abs(delta_vec.x):
			if delta_vec.y < 0.0:
				# ✅ swipe up: cancela duck y salta
				if _duck_holding:
					_end_duck()

				Input.action_press("jump")
				Input.action_release("jump")

			else:
				# ✅ swipe down: entra en duck por duck_hold_time
				Input.action_press("duck")
				_duck_holding = true
				_duck_timer = duck_hold_time

			_tracking = false

func _end_duck() -> void:
	_duck_holding = false
	_duck_timer = 0.0
	Input.action_release("duck")
