
extends Node2D

const FIELD_WIDTH := 1280.0
const FIELD_HEIGHT := 720.0
const GOAL_WIDTH := 180.0

func _draw() -> void:
	# Green turf background
	draw_rect(
		Rect2(0, 0, FIELD_WIDTH, FIELD_HEIGHT),
		Color("#176B49")
	)

	# Alternating turf stripes
	for i in range(8):
		if i % 2 == 0:
			draw_rect(
				Rect2(i * 160, 0, 160, FIELD_HEIGHT),
				Color("#1C7551")
			)

	# Outer field lines
	draw_rect(
		Rect2(20, 20, 1240, 680),
		Color.WHITE,
		false,
		3.0
	)

	# Goal positioned at the top
	var goal_left := (FIELD_WIDTH - GOAL_WIDTH) / 2.0

	draw_rect(
		Rect2(goal_left, 5, GOAL_WIDTH, 25),
		Color("#DCE4E8")
	)

	draw_line(
		Vector2(goal_left, 30),
		Vector2(goal_left + GOAL_WIDTH, 30),
		Color.WHITE,
		5.0
	)

	# Simplified shooting circle
	var points := PackedVector2Array()

	for i in range(65):
		var angle := PI - (PI * i / 64.0)

		points.append(
			Vector2(
				FIELD_WIDTH / 2.0 + cos(angle) * 260.0,
				30.0 + sin(angle) * 260.0
			)
		)

	draw_polyline(points, Color.WHITE, 3.0)

	# Penalty spot (illustrative)
	draw_circle(
		Vector2(FIELD_WIDTH / 2.0, 190),
		6.0,
		Color.WHITE
	)
