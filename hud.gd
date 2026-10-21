
extends CanvasLayer

var goals := 0
var saves := 0
var blocks := 0
var misses := 0

var scoreboard: Label
var message_label: Label

@onready var ball: Node2D = \
	get_parent().get_node("Ball")


func _ready() -> void:
	# Dark translucent background
	var panel := PanelContainer.new()
	panel.position = Vector2(15, 15)
	panel.custom_minimum_size = Vector2(470, 85)
	add_child(panel)

	var column := VBoxContainer.new()
	panel.add_child(column)

	var title := Label.new()
	title.text = "PENALTY CORNER CHALLENGE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	scoreboard = Label.new()
	scoreboard.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(scoreboard)

	message_label = Label.new()
	message_label.text = "Press SPACE to start"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(message_label)

	# Connect to the ball's signals.
	ball.corner_finished.connect(on_corner_finished)
	ball.event_reported.connect(on_event_reported)

	update_scoreboard()


func on_corner_finished(result: String) -> void:
	match result:
		"GOAL":
			goals += 1

		"SAVE":
			saves += 1

		"BLOCK":
			blocks += 1

		"MISS":
			misses += 1

	update_scoreboard()


func on_event_reported(message: String) -> void:
	message_label.text = message


func update_scoreboard() -> void:
	scoreboard.text = (
        "Goals: %d   Saves: %d   Blocks: %d   Misses: %d"
		% [goals, saves, blocks, misses]
	)
