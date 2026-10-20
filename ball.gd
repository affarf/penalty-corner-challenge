
extends Node2D

enum Phase {
	READY,
	INJECTING,
	STOPPED,
	PASSING,
	SHOOTING,
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

@export var injection_speed := 460.0
@export var pass_speed := 520.0
@export var shot_speed := 850.0

var phase := Phase.READY
var routine := Routine.DIRECT
var target := STOP_POSITION
var stop_timer := 0.0

@onready var goalkeeper = get_parent().get_node("Goalkeeper")


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
					print("Direct shot routine!")
					begin_shot()
				else:
					print("Slip pass routine!")
					phase = Phase.PASSING

		Phase.PASSING:
			position = position.move_toward(
				SLIP_POSITION,
				pass_speed * delta
			)

			if position.distance_to(SLIP_POSITION) < 1.0:
				print("Pass received! Shooting!")
				begin_shot()

		Phase.SHOOTING:
			var previous_position := global_position

			position = position.move_toward(
				target,
				shot_speed * delta
			)

			# Check the entire ball movement segment
			# so fast shots cannot skip over the keeper.
			var closest_point := \
				Geometry2D.get_closest_point_to_segment(
					goalkeeper.global_position,
					previous_position,
					global_position
				)

			var distance_to_keeper := \
				closest_point.distance_to(
					goalkeeper.global_position
				)

			var save_reach: float = \
				goalkeeper.get_save_reach()

			if goalkeeper.can_save() \
			and distance_to_keeper <= save_reach + 8.0:
				phase = Phase.FINISHED
				print("SAVED!")

			elif position.y <= GOAL_Y + 1.0:
				phase = Phase.FINISHED
				print("GOAL!")

		Phase.FINISHED:
			pass


func begin_shot() -> void:
	target = Vector2(
		randf_range(570.0, 710.0),
		GOAL_Y
	)

	phase = Phase.SHOOTING


func reset_corner() -> void:
	phase = Phase.READY
	position = INJECT_POSITION
	target = STOP_POSITION
	stop_timer = 0.0

	goalkeeper.reset_keeper()

	print("Reset! Press SPACE to start.")


func _draw() -> void:
	draw_circle(
		Vector2.ZERO,
		8.0,
		Color.WHITE
	)

	draw_arc(
		Vector2.ZERO,
		8.0,
		0.0,
		TAU,
		24,
		Color.DARK_GRAY,
		1.5
	)
