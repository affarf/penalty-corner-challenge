
extends CanvasLayer

const TOTAL_CORNERS := 10

var goals: int = 0
var saves: int = 0
var blocks: int = 0
var misses: int = 0
var corners_completed: int = 0

var session_active: bool = false
var awaiting_next: bool = false

var scoreboard: Label
var message_label: Label
var progress_label: Label

var menu_overlay: ColorRect
var results_overlay: ColorRect
var results_label: Label
var difficulty_select: OptionButton

@onready var ball = get_parent().get_node("Ball")


func _ready() -> void:
	ball.corner_finished.connect(on_corner_finished)
	ball.event_reported.connect(on_event_reported)

	build_hud()
	build_menu()
	build_results()

	ball.set_session_enabled(false)
	menu_overlay.visible = true
	results_overlay.visible = false
	update_scoreboard()


func make_label(
	value: String,
	font_size: int = 22
) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = \
		HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(
		"font_size", font_size
	)
	return label


func make_button(
	caption: String,
	callback: Callable
) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(260, 46)
	button.pressed.connect(callback)
	return button


func build_hud() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(15, 12)
	panel.custom_minimum_size = Vector2(590, 115)
	add_child(panel)

	var column := VBoxContainer.new()
	panel.add_child(column)

	column.add_child(
		make_label("PENALTY CORNER CHALLENGE", 20)
	)

	progress_label = make_label("CORNER 1 / 10", 17)
	column.add_child(progress_label)

	scoreboard = make_label("", 16)
	column.add_child(scoreboard)

	message_label = make_label(
		"Press SPACE to start", 15
	)
	column.add_child(message_label)


func make_overlay() -> ColorRect:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	overlay.color = Color(0.02, 0.10, 0.08, 0.94)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	return overlay


func make_centered_column(
	overlay: ColorRect
) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	overlay.add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override(
		"separation", 16
	)
	center.add_child(column)
	return column


func build_menu() -> void:
	menu_overlay = make_overlay()
	var column := make_centered_column(menu_overlay)

	column.add_child(
		make_label("PENALTY CORNER CHALLENGE", 36)
	)

	column.add_child(
		make_label("KEEPER MODE - 10 CORNERS", 22)
	)

	column.add_child(
		make_label(
			"WASD Move  |  Mouse Aim\n" +
			"Left Click Quick Save  |  Right Click Dive\n" +
			"SPACE Inject  |  R Next Corner",
			17
		)
	)

	difficulty_select = OptionButton.new()
	difficulty_select.add_item("Easy", 0)
	difficulty_select.add_item("Normal", 1)
	difficulty_select.add_item("Hard", 2)
	difficulty_select.select(1)
	column.add_child(difficulty_select)

	column.add_child(
		make_button("START CHALLENGE", start_session)
	)


func build_results() -> void:
	results_overlay = make_overlay()
	var column := make_centered_column(
		results_overlay
	)

	column.add_child(
		make_label("CHALLENGE COMPLETE!", 34)
	)

	results_label = make_label("", 21)
	column.add_child(results_label)

	column.add_child(
		make_button("PLAY AGAIN", restart_session)
	)


func start_session() -> void:
	goals = 0
	saves = 0
	blocks = 0
	misses = 0
	corners_completed = 0

	session_active = true
	awaiting_next = false

	# Enable before reset.
	ball.set_session_enabled(true)
	ball.reset_corner()

	ball.set_difficulty(
		difficulty_select.get_selected_id()
	)

	menu_overlay.visible = false
	results_overlay.visible = false

	message_label.text = \
        "Behind the line - press SPACE to inject"

	update_scoreboard()


func restart_session() -> void:
	start_session()


func on_corner_finished(result: String) -> void:
	if not session_active or awaiting_next:
		return

	match result:
		"GOAL":
			goals += 1
		"SAVE":
			saves += 1
		"BLOCK":
			blocks += 1
		"MISS":
			misses += 1

	corners_completed += 1
	awaiting_next = true
	update_scoreboard()

	if corners_completed >= TOTAL_CORNERS:
		finish_session()
	else:
		message_label.text = \
            "Corner complete! Press R for next."


func on_event_reported(message: String) -> void:
	if not session_active or awaiting_next:
		return

	message_label.text = message


func update_scoreboard() -> void:
	scoreboard.text = (
        "Goals: %d   Saves: %d   Blocks: %d   Misses: %d"
		% [goals, saves, blocks, misses]
	)

	progress_label.text = "CORNERS %d / %d" % [
		corners_completed,
		TOTAL_CORNERS
	]


func finish_session() -> void:
	session_active = false
	ball.set_session_enabled(false)

	var defended: int = (
		TOTAL_CORNERS - goals
	)

	var percentage: int = roundi(
		float(defended) /
		float(TOTAL_CORNERS) * 100.0
	)

	results_label.text = (
		"Corners: %d\n" +
		"Goals conceded: %d\n" +
		"Goalkeeper saves: %d\n" +
		"Runner blocks: %d\n" +
		"Missed shots: %d\n\n" +
        "DEFENDED: %d%%"
	) % [
		TOTAL_CORNERS,
		goals,
		saves,
		blocks,
		misses,
		percentage
	]

	results_overlay.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not session_active:
		return

	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_R:
				if awaiting_next:
					awaiting_next = false
					ball.reset_corner()

					message_label.text = \
                        "Back on the line. Press SPACE."
