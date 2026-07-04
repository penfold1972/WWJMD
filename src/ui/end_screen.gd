extends CanvasLayer

## WWJMD End Screen — Play Again / Quit menu
## Wired to the getaway van exit trigger

func _ready():
	# The tree is paused while this screen is up — keep processing so buttons work
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build_ui()

func _build_ui() -> void:
	# Dimmed background
	var bg = ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.0, 0.0, 0.0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Centered menu column
	var menu = VBoxContainer.new()
	menu.name = "Menu"
	menu.set_anchors_preset(Control.PRESET_CENTER)
	menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	menu.grow_vertical = Control.GROW_DIRECTION_BOTH
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	menu.add_theme_constant_override("separation", 16)
	bg.add_child(menu)

	var title = Label.new()
	title.name = "Title"
	title.text = "MISSION COMPLETE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	menu.add_child(title)

	var again = Button.new()
	again.name = "PlayAgainBtn"
	again.text = "Play Again"
	again.custom_minimum_size = Vector2(200, 50)
	again.pressed.connect(_on_play_again)
	menu.add_child(again)

	var quit = Button.new()
	quit.name = "QuitBtn"
	quit.text = "Quit Game"
	quit.custom_minimum_size = Vector2(200, 50)
	quit.pressed.connect(_on_quit)
	menu.add_child(quit)

func _on_play_again() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit() -> void:
	get_tree().quit()
