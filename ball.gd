
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

const INJECT_POSITION := Vector2(320, 30)
const STOP_POSITION := Vector2(640, 340)
const SLIP_POSITION := Vector2(830, 310)

const GOAL_Y := 30.0
const GOAL_LEFT := 550.0
const GOAL_RIGHT := 730.0
const BALL_RADIUS := 8.0

@export var injection_speed := 460.0
@export var pass_speed := 520.0
@export var shot_speed := 850.0

@export var rebound_speed := 480.0
@export var rebound_friction := 600.0

var phase := Phase.READY
var routine := Routine.DIRECT

var target := STOP_POSITION
var stop_timer := 0.0

var rebound_velocity := Vector2.ZERO


@onready var goalkeeper: CharacterBody2D = \
	get_parent().get_node("Goalkeeper")



func _ready() -> void:
	position = INJECT_POSITION


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

	print("Penalty corner started!")


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
					print("Direct shot!")
					begin_shot()
				else:
					print("Slip pass!")
					phase = Phase.PASSING

		Phase.PASSING:
			position = position.move_toward(
				SLIP_POSITION,
				pass_speed * delta
			)

			if position.distance_to(SLIP_POSITION) < 1.0:
				print("Slip received!")
				begin_shot()

		Phase.SHOOTING:
			process_shot(delta)

		Phase.REBOUND:
			process_rebound(delta)

		Phase.FINISHED:
			pass


func begin_shot() -> void:
	target = Vector2(
		randf_range(565.0, 715.0),
		GOAL_Y
	)

	phase = Phase.SHOOTING


func process_shot(delta: float) -> void:
	var previous_position := global_position

	position = position.move_toward(
		target,
		shot_speed * delta
	)

	var closest_point := \
		Geometry2D.get_closest_point_to_segment(
			goalkeeper.global_position,
			previous_position,
			global_position
		)

	# Only an active, correctly aimed save can
	# stop the incoming shot.
	if goalkeeper.can_block_ball(closest_point):
		global_position = closest_point
		make_rebound()
		return

	# Check if the ball reached the goal line.
	if position.y <= GOAL_Y + 0.01:
		if position.x >= GOAL_LEFT \
		and position.x <= GOAL_RIGHT:
			print("GOAL!")
		else:
			print("WIDE! Shot missed the goal.")

		phase = Phase.FINISHED


func make_rebound() -> void:
	phase = Phase.REBOUND

	# Rebound generally travels away from goal.
	# The chosen save direction influences
	# which side the ball travels toward.

	var clearance_direction: Vector2 = (
		Vector2.DOWN * 0.85 +
		goalkeeper.save_direction * 0.35
	).normalized()


	rebound_velocity = clearance_direction * rebound_speed

	print("SAVED! Ball is still in play!")


func process_rebound(delta: float) -> void:
	# Move the ball across the turf.
	position += rebound_velocity * delta

	# Gradually slow it down.
	rebound_velocity = rebound_velocity.move_toward(
		Vector2.ZERO,
		rebound_friction * delta
	)

	# Keep rebound within the game window.
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
		print("Rebound stopped. Press R to reset.")


func reset_corner() -> void:
	phase = Phase.READY
	position = INJECT_POSITION
	target = STOP_POSITION
	stop_timer = 0.0
	rebound_velocity = Vector2.ZERO

	goalkeeper.reset_keeper()

	print("Reset! Press SPACE to start.")


func _draw() -> void:
	draw_circle(
		Vector2.ZERO,
		BALL_RADIUS,
		Color.WHITE
	)

	draw_arc(
		Vector2.ZERO,
		BALL_RADIUS,
		0.0,
		TAU,
		24,
		Color.DARK_GRAY,
		1.5
	)
