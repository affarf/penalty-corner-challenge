
extends Node2D

enum Phase {
	READY,
	INJECTING,
	STOPPED,
	SHOOTING,
	FINISHED
}

const INJECT_POSITION := Vector2(320, 30)
const STOP_POSITION := Vector2(640, 340)
const GOAL_Y := 30.0

@export var injection_speed := 460.0
@export var shot_speed := 850.0

var phase := Phase.READY
var target := STOP_POSITION
var stop_timer := 0.0

@onready var goalkeeper: CharacterBody2D = \
	get_parent().get_node("Goalkeeper")


func _ready() -> void:
	position = INJECT_POSITION


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_SPACE:
				if phase == Phase.READY:
					phase = Phase.INJECTING
					print("Penalty corner started!")

			if event.keycode == KEY_R:
				reset_corner()


func _physics_process(delta: float) -> void:
	match phase:
		Phase.INJECTING:
			position = position.move_toward(
				STOP_POSITION,
				injection_speed * delta
			)

			if position.distance_to(STOP_POSITION) < 1.0:
				phase = Phase.STOPPED
				stop_timer = 0.5
				print("Ball stopped outside the D!")

		Phase.STOPPED:
			stop_timer -= delta

			if stop_timer <= 0.0:
				target = Vector2(
					randf_range(565, 715),
					GOAL_Y
				)
				phase = Phase.SHOOTING
				print("Shot!")

		Phase.SHOOTING:
			position = position.move_toward(
				target,
				shot_speed * delta
			)

			# Temporary goalkeeper save detection.
			if position.distance_to(
				goalkeeper.global_position
			) < 32.0:
				phase = Phase.FINISHED
				print("SAVED!")

			elif position.y <= GOAL_Y + 1.0:
				phase = Phase.FINISHED
				print("GOAL!")


func reset_corner() -> void:
	phase = Phase.READY
	position = INJECT_POSITION
	target = STOP_POSITION
	stop_timer = 0.0
	print("Corner reset. Press SPACE to start.")


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
