extends CanvasLayer

## WWJMD End Screen — Play Again / Quit menu
## Wired to the getaway van exit trigger

func _ready():
	build_ui()

func build_ui() -> void:
	# Dimmed background
	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.7)
	bg.anchors_preset = 15  # full rect
	bg.name = "BG"
	add_child(bg)

	# Title
	var title = Label.new()
	title.text = "MISSION COMPLETE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.position = Vector2(0, -60)
	title.name = "Title"
	bg.add_child(title)

	# Play Again button
	var again = Button.new()
	again.text = "Play Again"
	again.position = Vector2(100, 60)
	again.size = Vector2(200, 50)
	again.name = "PlayAgainBtn"
	again.pressed.connect(_on_play_again)
	bg.add_child(again)

	# Quit button
	var quit = Button.new()
	quit.text = "Quit Game"
	quit.position = Vector2(100, 130)
	quit.size = Vector2(200, 50)
	quit.name = "QuitBtn"
	quit.pressed.connect(_on_quit)
	bg.add_child(quit)

func _on_play_again() -> void:
	get_tree().reload_current_scene()

func _on_quit() -> void:
	get_tree().quit()
