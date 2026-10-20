
extends CharacterBody2D

@export var speed: float = 320.0

const FIELD_MIN := Vector2(45, 45)
const FIELD_MAX := Vector2(1235, 675)

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
        "ui_down"
	)

	velocity = direction * speed
	move_and_slide()

	global_position = global_position.clamp(
		FIELD_MIN,
		FIELD_MAX
	)

func _draw() -> void:
	draw_circle(
		Vector2.ZERO,
		24.0,
		Color.DODGER_BLUE
	)

	draw_arc(
		Vector2.ZERO,
		24.0,
		0.0,
		TAU,
		32,
		Color.WHITE,
		3.0
	)
