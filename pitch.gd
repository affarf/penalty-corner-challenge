
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


	# Goal and backline at y = 80
	var goal_left: float = (
		FIELD_WIDTH - GOAL_WIDTH
	) / 2.0

	draw_rect(
		Rect2(goal_left, 48, GOAL_WIDTH, 32),
		Color("#DCE4E8")
	)

	draw_line(
		Vector2(20, 80),
		Vector2(1260, 80),
		Color.WHITE,
		3.0
	)

	# Enlarged shooting circle
	var points := PackedVector2Array()

	for i in range(65):
		var angle: float = PI - PI * i / 64.0

		points.append(
			Vector2(
				FIELD_WIDTH / 2.0 +
					cos(angle) * 295.0,
				80.0 + sin(angle) * 295.0
			)
		)

	draw_polyline(points, Color.WHITE, 3.0)

	draw_circle(
		Vector2(640, 240),
		6.0,
		Color.WHITE
	)
