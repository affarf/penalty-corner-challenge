
extends CharacterBody2D

signal save_attempted(kind: String)

@export var speed: float = 320.0
@export var dive_speed: float = 650.0

const FIELD_MIN := Vector2(45, 45)
const FIELD_MAX := Vector2(1235, 675)

const QUICK_DURATION := 0.20
const QUICK_RECOVERY := 0.25

const DIVE_DURATION := 0.35
const DIVE_RECOVERY := 0.80

enum State {
	READY,
	QUICK_SAVE,
	DIVING,
	RECOVERING
}

var state := State.READY
var state_timer := 0.0
var dive_direction := Vector2.ZERO
var recovery_duration := 0.0


func _physics_process(delta: float) -> void:
	match state:
		State.READY:
			handle_movement()

		State.QUICK_SAVE:
			velocity = Vector2.ZERO
			move_and_slide()
			state_timer -= delta

			if state_timer <= 0.0:
				start_recovery(QUICK_RECOVERY)

		State.DIVING:
			velocity = dive_direction * dive_speed
			move_and_slide()
			state_timer -= delta

			if state_timer <= 0.0:
				start_recovery(DIVE_RECOVERY)

		State.RECOVERING:
			velocity = Vector2.ZERO
			state_timer -= delta

			if state_timer <= 0.0:
				state = State.READY

	global_position = global_position.clamp(
		FIELD_MIN,
		FIELD_MAX
	)

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if state != State.READY:
		return

	if event.is_action_pressed("quick_save"):
		start_quick_save()

	elif event.is_action_pressed("dive"):
		start_dive()


func handle_movement() -> void:
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)

	velocity = direction * speed
	move_and_slide()


func start_quick_save() -> void:
	state = State.QUICK_SAVE
	state_timer = QUICK_DURATION
	velocity = Vector2.ZERO

	save_attempted.emit("quick")
	print("Quick save!")


func start_dive() -> void:
	var mouse_direction := (
		get_global_mouse_position() - global_position
	).normalized()

	if mouse_direction.length() < 0.01:
		return

	dive_direction = mouse_direction
	state = State.DIVING
	state_timer = DIVE_DURATION

	save_attempted.emit("dive")
	print("Diving!")


func start_recovery(duration: float) -> void:
	state = State.RECOVERING
	state_timer = duration
	recovery_duration = duration


func can_save() -> bool:
	return state == State.QUICK_SAVE \
		or state == State.DIVING


func get_save_reach() -> float:
	if state == State.DIVING:
		return 46.0

	if state == State.QUICK_SAVE:
		return 38.0

	return 24.0


func reset_keeper() -> void:
	state = State.READY
	state_timer = 0.0
	velocity = Vector2.ZERO
	global_position = Vector2(640, 75)


func _draw() -> void:
	var body_color := Color.DODGER_BLUE

	match state:
		State.QUICK_SAVE:
			body_color = Color.YELLOW

		State.DIVING:
			body_color = Color.ORANGE

		State.RECOVERING:
			body_color = Color.GRAY

	draw_circle(Vector2.ZERO, 24.0, body_color)

	draw_arc(
		Vector2.ZERO,
		get_save_reach(),
		0.0,
		TAU,
		40,
		Color.WHITE,
		2.0
	)

	if state == State.DIVING:
		draw_line(
			Vector2.ZERO,
			dive_direction * 55.0,
			Color.WHITE,
			4.0
		)
