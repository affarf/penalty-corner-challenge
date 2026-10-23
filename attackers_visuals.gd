
extends Node2D


const INJECTOR_POS := Vector2(320, 80)
const STOPPER_POS := Vector2(640, 420)
const SLIP_POS := Vector2(830, 390)


@onready var ball: CornerBall = \
	get_parent().get_node("Ball") as CornerBall

var animation_time: float = 0.0


func _process(delta: float) -> void:
	animation_time += delta
	queue_redraw()


func _draw() -> void:
	draw_attacker(
		INJECTOR_POS,
		Color.ORANGE,
		-0.7
	)

	var swing_angle: float = 0.0

	if ball.phase == CornerBall.Phase.FAKING:
		# A quick, exaggerated stick swing.
		var fake_progress: float = 1.0 - \
			ball.fake_timer / 0.65

		swing_angle = sin(
			fake_progress * PI
		) * 1.6

	elif ball.phase == CornerBall.Phase.STOPPED:
		# Subtle preparation before shooting.
		swing_angle = sin(
			animation_time * 6.0
		) * 0.18

	draw_attacker(
		STOPPER_POS,
		Color.ORANGE,
		swing_angle
	)

	draw_attacker(
		SLIP_POS,
		Color.ORANGE_RED,
		-0.4
	)


func draw_attacker(
	center: Vector2,
	shirt_color: Color,
	stick_angle: float
) -> void:
	# Player shadow
	draw_circle(
		center + Vector2(3, 4),
		17.0,
		Color(0, 0, 0, 0.25)
	)

	# Player body
	draw_circle(
		center,
		15.0,
		shirt_color
	)

	draw_arc(
		center,
		15.0,
		0.0,
		TAU,
		32,
		Color.WHITE,
		2.0
	)

	# Stick rotates around the player.
	var stick_start := center + Vector2(8, 5)

	var stick_end := stick_start + \
		Vector2(0, -29).rotated(stick_angle)

	draw_line(
		stick_start,
		stick_end,
		Color("#EED7AC"),
		4.0
	)

	draw_circle(
		stick_end,
		3.0,
		Color.WHITE
	)
