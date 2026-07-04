extends CanvasLayer

## WWJMD HUD — crosshair, score readout, interact prompt, objective hint

var _stats_label: Label
var _interact_label: Label

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

	# Score readout (top-left)
	_stats_label = Label.new()
	_stats_label.name = "Stats"
	_stats_label.text = _stats_text(0, 0, 0)
	_stats_label.add_theme_font_size_override("font_size", 20)
	_stats_label.position = Vector2(16, 12)
	add_child(_stats_label)

	# Interact prompt — sits just below the crosshair, hidden until a
	# collectible is in range under the crosshair
	_interact_label = Label.new()
	_interact_label.name = "InteractPrompt"
	_interact_label.text = "[E] Collect"
	_interact_label.add_theme_font_size_override("font_size", 18)
	_interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interact_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_interact_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_interact_label.offset_top = 60.0
	_interact_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interact_label.visible = false
	add_child(_interact_label)

	# Objective hint (bottom-center)
	var hint = Label.new()
	hint.name = "ObjectiveHint"
	hint.text = "Collect snacks with E for points — shooting them costs you! Escape to the van when done."
	hint.add_theme_font_size_override("font_size", 16)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint.offset_bottom = -24.0
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

func set_stats(collected: int, destroyed: int, score: int) -> void:
	_stats_label.text = _stats_text(collected, destroyed, score)

func show_interact_prompt(visible_now: bool) -> void:
	_interact_label.visible = visible_now

func _stats_text(collected: int, destroyed: int, score: int) -> String:
	return "Collected: %d\nDestroyed: %d\nScore: %d" % [collected, destroyed, score]
