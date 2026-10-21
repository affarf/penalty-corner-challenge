
extends Node2D

enum Phase {
	READY,
	INJECTING,
	STOPPED,
	PASSING,
	SHOOTING,
	REBOUND,
	FINISHED
}

enum Routine {
	DIRECT,
	SLIP_PASS
}

enum ShotType {
	LOW,
	DRAG_FLICK
}

const INJECT_POSITION := Vector2(320, 30)
const STOP_POSITION := Vector2(640, 340)
const SLIP_POSITION := Vector2(830, 310)

const GOAL_Y := 30.0
const GOAL_LEFT := 550.0
const GOAL_RIGHT := 730.0
const GOAL_BAR_HEIGHT := 90.0
const BALL_RADIUS := 8.0

@export var injection_speed := 460.0
@export var pass_speed := 520.0
@export var shot_speed := 850.0
@export var rebound_speed := 480.0
@export var rebound_friction := 600.0

var phase := Phase.READY
var routine := Routine.DIRECT
var shot_type := ShotType.LOW

var target: Vector2 = STOP_POSITION
var stop_timer := 0.0

var ball_height: float = 0.0
var peak_height: float = 0.0
var shot_start_position := Vector2.ZERO
var shot_total_distance: float = 1.0

var rebound_velocity := Vector2.ZERO

signal event_reported(message: String)
signal corner_finished(result: String)

@onready var goalkeeper = \
	get_parent().get_node("Goalkeeper")
	
@onready var runner: DefensiveRunner = \
	get_parent().get_node("DefensiveRunner") as DefensiveRunner


func _ready() -> void:
	position = INJECT_POSITION
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_SPACE:
				if phase == Phase.READY:
					start_corner()

			elif event.keycode == KEY_R:
				reset_corner()



func start_corner() -> void:
	routine = Routine.values().pick_random()
	phase = Phase.INJECTING

	runner.start_run()

	event_reported.emit("Corner injected!")
	print("Corner started! Runner released!")



func _physics_process(delta: float) -> void:
	match phase:
		Phase.INJECTING:
			position = position.move_toward(
				STOP_POSITION,
				injection_speed * delta
			)

			if position.distance_to(STOP_POSITION) < 1.0:
				phase = Phase.STOPPED
				stop_timer = 0.45
				print("Ball trapped outside the D!")

		Phase.STOPPED:
			stop_timer -= delta

			if stop_timer <= 0.0:
				if routine == Routine.DIRECT:
					begin_shot()
				else:
					phase = Phase.PASSING
					print("Slip pass!")

		Phase.PASSING:
			position = position.move_toward(
				SLIP_POSITION,
				pass_speed * delta
			)

			if position.distance_to(SLIP_POSITION) < 1.0:
				begin_shot()

		Phase.SHOOTING:
			process_shot(delta)

		Phase.REBOUND:
			process_rebound(delta)

		Phase.FINISHED:
			pass

	queue_redraw()


func begin_shot() -> void:
	shot_type = ShotType.values().pick_random()

	target = Vector2(
		randf_range(565.0, 715.0),
		GOAL_Y
	)

	shot_start_position = position
	shot_total_distance = maxf(
		position.distance_to(target),
		1.0
	)

	if shot_type == ShotType.DRAG_FLICK:
		peak_height = randf_range(65.0, 145.0)
		print("DRAG FLICK! Watch the height!")
	else:
		peak_height = 0.0
		print("LOW SHOT!")

	ball_height = 0.0
	phase = Phase.SHOOTING


func process_shot(delta: float) -> void:
	var previous_position: Vector2 = global_position

	var previous_height: float = ball_height

	var remaining_distance: float = \
		position.distance_to(target)

	var shot_direction: Vector2 = \
		(target - position).normalized()

	# Move toward goal.
	position = position.move_toward(
		target,
		shot_speed * delta
	)

	# Simulate height for elevated drag flicks.
	var distance_travelled: float = \
		shot_start_position.distance_to(position)

	var progress: float = clampf(
		distance_travelled / shot_total_distance,
		0.0,
		1.0
	)

	if shot_type == ShotType.DRAG_FLICK:
		ball_height = peak_height * sin(
			progress * PI * 0.75
		)
	else:
		ball_height = 0.0

	# Find the closest point on the ball's
	# movement path to the goalkeeper.
	var closest_point: Vector2 = \
		Geometry2D.get_closest_point_to_segment(
			goalkeeper.global_position,
			previous_position,
			global_position
		)

	# Approximate height at the closest point.
	var movement: Vector2 = \
		global_position - previous_position

	var segment_length_squared: float = \
		movement.length_squared()

	var contact_fraction: float = 0.0

	if segment_length_squared > 0.0001:
		contact_fraction = clampf(
			(closest_point - previous_position).dot(
				movement
			) / segment_length_squared,
			0.0,
			1.0
		)

	var contact_height: float = lerpf(
		previous_height,
		ball_height,
		contact_fraction
	)
	
	
	# Check if the first runner blocks the shot.
	if runner.can_block(
		previous_position,
		global_position,
		contact_height
	):
		phase = Phase.REBOUND
		ball_height = 0.0

		# Simple sideways deflection away
		# from the original shot path.
		rebound_velocity = Vector2(
			320.0,
			280.0
		)

		runner.active = false

		corner_finished.emit("BLOCK")
		event_reported.emit("Runner blocked the shot!")
		print("FIRST RUNNER BLOCK!")
		return


	if goalkeeper.can_block_shot(
		closest_point,
		contact_height
	):
		global_position = closest_point
		ball_height = 0.0
		make_rebound()
		corner_finished.emit("SAVE")
		event_reported.emit("Goalkeeper save!")
		return

	# Goal mouth and crossbar checks.

	if position.y <= GOAL_Y + 0.01:
		if position.x < GOAL_LEFT \
		or position.x > GOAL_RIGHT:
			print("WIDE!")
			corner_finished.emit("MISS")
			event_reported.emit("Shot missed!")

		elif ball_height > GOAL_BAR_HEIGHT:
			print("OVER THE CROSSBAR!")
			corner_finished.emit("MISS")
			event_reported.emit("Over the crossbar!")

		else:
			print("GOAL!")
			corner_finished.emit("GOAL")
			event_reported.emit("Goal conceded!")

		phase = Phase.FINISHED



func make_rebound() -> void:
	phase = Phase.REBOUND
	ball_height = 0.0

	var clearance_direction: Vector2 = (
		Vector2.DOWN * 0.85 +
		goalkeeper.save_direction * 0.35
	).normalized()

	rebound_velocity = (
		clearance_direction * rebound_speed
	)

	print("SAVED! REBOUND!")


func process_rebound(delta: float) -> void:
	position += rebound_velocity * delta

	rebound_velocity = rebound_velocity.move_toward(
		Vector2.ZERO,
		rebound_friction * delta
	)

	position.x = clampf(
		position.x,
		BALL_RADIUS,
		1280.0 - BALL_RADIUS
	)

	position.y = clampf(
		position.y,
		BALL_RADIUS,
		720.0 - BALL_RADIUS
	)

	if rebound_velocity.length() < 1.0:
		rebound_velocity = Vector2.ZERO
		phase = Phase.FINISHED
		print("Rebound stopped. Press R.")


func reset_corner() -> void:
	phase = Phase.READY
	position = INJECT_POSITION
	target = STOP_POSITION
	stop_timer = 0.0

	ball_height = 0.0
	peak_height = 0.0
	rebound_velocity = Vector2.ZERO

	goalkeeper.reset_keeper()
	queue_redraw()
	runner.reset_runner()
	event_reported.emit("Press SPACE to start")

	print("Press SPACE to start.")
	


func _draw() -> void:
	# Ground shadow marks actual pitch location.
	if ball_height > 1.0:
		draw_circle(
			Vector2.ZERO,
			BALL_RADIUS,
			Color(0.0, 0.0, 0.0, 0.35)
		)

	# Elevated ball appears above its shadow.
	var visual_offset := Vector2(
		0.0,
		-ball_height * 0.35
	)

	draw_circle(
		visual_offset,
		BALL_RADIUS,
		Color.WHITE
	)

	draw_arc(
		visual_offset,
		BALL_RADIUS,
		0.0,
		TAU,
		24,
		Color.DARK_GRAY,
		1.5
	)
