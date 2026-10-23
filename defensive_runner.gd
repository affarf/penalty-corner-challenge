
class_name DefensiveRunner
extends Node2D

const START_POSITION := Vector2(735, 50)
const BLOCK_POSITION := Vector2(665, 235)

@export var run_speed: float = 520.0
@export var block_radius: float = 22.0

var running := false
var active := false


func _ready() -> void:
	reset_runner()


func start_run() -> void:
	global_position = START_POSITION
	running = true
	active = true


func reset_runner() -> void:
	running = false
	active = false
	global_position = START_POSITION
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not running:
		return

	global_position = global_position.move_toward(
		BLOCK_POSITION,
		run_speed * delta
	)

	if global_position.distance_to(
		BLOCK_POSITION
	) < 1.0:
		running = false


func can_block(
	from_position: Vector2,
	to_position: Vector2,
	height: float
) -> bool:
	if not active:
		return false

	# Only block balls low enough for a
	# basic stick interception.
	if height > 25.0:
		return false

	var closest: Vector2 = \
		Geometry2D.get_closest_point_to_segment(
			global_position,
			from_position,
			to_position
		)

	return closest.distance_to(
		global_position
	) <= block_radius


func _draw() -> void:
	draw_circle(
		Vector2.ZERO,
		16.0,
		Color.CYAN
	)

	draw_arc(
		Vector2.ZERO,
		16.0,
		0.0,
		TAU,
		32,
		Color.WHITE,
		2.0
	)

	# Stick representation
	draw_line(
		Vector2(8, 4),
		Vector2(23, 20),
		Color.WHITE,
		3.0
	)
