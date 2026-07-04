extends CanvasLayer

## WWJMD HUD — crosshair, snack counter, objective hint

var _snack_label: Label

func _ready():
	_build_ui()

func _build_ui() -> void:
	# Crosshair — full-rect label with centered text stays centered on resize
	var crosshair = Label.new()
	crosshair.name = "Crosshair"
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 24)
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.set_anchors_preset(Control.PRESET_FULL_RECT)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(crosshair)

	# Snack counter (top-left)
	_snack_label = Label.new()
	_snack_label.name = "SnackCounter"
	_snack_label.text = "Snacks destroyed: 0"
	_snack_label.add_theme_font_size_override("font_size", 20)
	_snack_label.position = Vector2(16, 12)
	add_child(_snack_label)

	# Objective hint (bottom-center)
	var hint = Label.new()
	hint.name = "ObjectiveHint"
	hint.text = "Trash the snacks, then escape to the getaway van outside!"
	hint.add_theme_font_size_override("font_size", 16)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint.offset_bottom = -24.0
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

func set_snack_count(count: int) -> void:
	_snack_label.text = "Snacks destroyed: %d" % count
