extends Control
## Hauptmenue: Titel, Start, Steuerungsuebersicht, Beenden.

func _ready() -> void:
	# Headless-Tests und Autostart ueberspringen das Menue
	if DisplayServer.get_name() == "headless" or OS.get_environment("PANEM_AUTOSTART") == "1":
		get_tree().change_scene_to_file.call_deferred("res://scenes/arena/arena.tscn")
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Color(0.06, 0.07, 0.09)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var box := VBoxContainer.new()
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -260
	box.offset_right = 260
	box.offset_top = -220
	box.offset_bottom = 240
	box.add_theme_constant_override("separation", 14)
	add_child(box)

	var title := Label.new()
	title.text = "PANEM ARENA"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.95, 0.8, 0.35))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Die 74. Spiele — 24 Tribute. Eine Arena. Ein:e Sieger:in."
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)

	box.add_child(HSeparator.new())

	var start_button := Button.new()
	start_button.text = "Die Spiele beginnen"
	start_button.custom_minimum_size = Vector2(0, 48)
	start_button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://ui/reaping.tscn"))
	box.add_child(start_button)

	var controls := Label.new()
	controls.text = "WASD bewegen · Maus umsehen · Shift sprinten · Leertaste springen\nE aufheben/trinken · F essen/platzieren · 1-6 Slots · LMB Angriff\n\nUeberlebe Durst, Hunger, Kaelte, Jaegerwespen — und die anderen 23."
	controls.add_theme_font_size_override("font_size", 15)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(controls)

	var quit_button := Button.new()
	quit_button.text = "Beenden"
	quit_button.custom_minimum_size = Vector2(0, 40)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	box.add_child(quit_button)

	start_button.grab_focus()
