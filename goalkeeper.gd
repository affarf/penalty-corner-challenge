
extends CharacterBody2D

signal save_attempted(kind: String)

@export var speed: float = 320.0
@export var dive_speed: float = 220.0
@export var max_dive_distance: float = 42.0

const FIELD_MIN := Vector2(45, 45)
const FIELD_MAX := Vector2(1235, 675)
const START_POSITION := Vector2(640, 50)

const QUICK_DURATION := 0.20
const QUICK_RECOVERY := 0.25

const DIVE_DURATION := 0.25
const DIVE_RECOVERY := 0.65

enum State {
	READY,
	QUICK_SAVE,
	DIVING,
	RECOVERING
}

var state: State = State.READY
var state_timer: float = 0.0

var corner_released: bool = false

var dive_direction: Vector2 = Vector2.ZERO
var dive_target: Vector2 = Vector2.ZERO
var save_direction: Vector2 = Vector2.UP
var last_move_direction: Vector2 = Vector2.LEFT


func _ready() -> void:
	reset_keeper()


func _physics_process(delta: float) -> void:
	# Stay behind the goal line before injection.
	if not corner_released:
		velocity = Vector2.ZERO
		position = START_POSITION
		queue_redraw()
		return

	match state:
		State.READY:
			handle_movement()

		State.QUICK_SAVE:
			velocity = Vector2.ZERO
			state_timer -= delta

			if state_timer <= 0.0:
				start_recovery(QUICK_RECOVERY)

		State.DIVING:
			var remaining: float = position.distance_to(
				dive_target
			)

			if remaining > 1.0:
				velocity = dive_direction * minf(
					dive_speed,
					remaining / maxf(delta, 0.0001)
				)
				move_and_slide()
			else:
				velocity = Vector2.ZERO

			state_timer -= delta

			if state_timer <= 0.0:
				start_recovery(DIVE_RECOVERY)

		State.RECOVERING:
			velocity = Vector2.ZERO
			state_timer -= delta

			if state_timer <= 0.0:
				state = State.READY

	# Restrict the keeper to the local pitch.
	position = position.clamp(
		FIELD_MIN,
		FIELD_MAX
	)

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not corner_released:
		return

	if state != State.READY:
		return

	if event.is_action_pressed("quick_save"):
		start_quick_save()

	elif event.is_action_pressed("dive"):
		start_dive()


func handle_movement() -> void:
	var direction: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)

	if direction.length() > 0.01:
		last_move_direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()


func start_quick_save() -> void:
	var mouse_direction: Vector2 = (
		get_global_mouse_position() - global_position
	).normalized()

	if mouse_direction.length() > 0.01:
		save_direction = mouse_direction

	state = State.QUICK_SAVE
	state_timer = QUICK_DURATION
	velocity = Vector2.ZERO

	save_attempted.emit("quick")
	print("Quick save!")


func start_dive() -> void:
	# Dive direction comes from WASD, not mouse.
	var direction: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)

	if direction.length() < 0.01:
		direction = last_move_direction

	dive_direction = direction.normalized()
	save_direction = dive_direction

	# Local coordinates keep the dive on the pitch.
	dive_target = (
		position + dive_direction * max_dive_distance
	).clamp(FIELD_MIN, FIELD_MAX)

	state = State.DIVING
	state_timer = DIVE_DURATION
	velocity = Vector2.ZERO

	save_attempted.emit("dive")
	print("Diving!")


func start_recovery(duration: float) -> void:
	state = State.RECOVERING
	state_timer = duration
	velocity = Vector2.ZERO


func can_save() -> bool:
	return state == State.QUICK_SAVE \
		or state == State.DIVING


func get_save_reach() -> float:
	if state == State.DIVING:
		return 65.0

	if state == State.QUICK_SAVE:
		return 42.0

	return 24.0


func can_block_ball(ball_position: Vector2) -> bool:
	if not can_save():
		return false

	# Ball coordinates are global for collision checks.
	var to_ball: Vector2 = ball_position - global_position
	var distance: float = to_ball.length()

	if state == State.QUICK_SAVE:
		if distance > 42.0:
			return false

		if distance < 18.0:
			return true

		return save_direction.dot(
			to_ball.normalized()
		) >= 0.35

	if state == State.DIVING:
		var forward: float = to_ball.dot(
			dive_direction
		)

		var sideways: float = absf(
			to_ball.cross(dive_direction)
		)

		return (
			forward >= -12.0
			and forward <= 65.0
			and sideways <= 22.0
		)

	return false


func can_block_shot(
	ball_position: Vector2,
	ball_height: float
) -> bool:
	if not can_block_ball(ball_position):
		return false

	match state:
		State.QUICK_SAVE:
			return ball_height <= 22.0

		State.DIVING:
			return ball_height <= 95.0

		_:
			return false


func reset_keeper() -> void:
	state = State.READY
	state_timer = 0.0
	velocity = Vector2.ZERO

	position = START_POSITION
	corner_released = false

	dive_direction = Vector2.ZERO
	dive_target = position
	save_direction = Vector2.UP
	last_move_direction = Vector2.LEFT

	queue_redraw()


func release_from_line() -> void:
	corner_released = true
	print("Ball injected! Goalkeeper released.")


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
		var forward: Vector2 = dive_direction.normalized()
		var sideways: Vector2 = Vector2(
			-forward.y,
			forward.x
		)

		var body_points := PackedVector2Array([
			forward * 34.0 + sideways * 10.0,
			forward * 34.0 - sideways * 10.0,
			-forward * 10.0 - sideways * 10.0,
			-forward * 10.0 + sideways * 10.0
		])

		draw_colored_polygon(
			body_points,
			Color.ORANGE
		)
