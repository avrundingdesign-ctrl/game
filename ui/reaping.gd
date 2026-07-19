extends Control
## Die Ernte (Reaping): kurzer Vorspann vor der Arena — Distrikt-Montage,
## dann die dramatische Ziehung fuer Distrikt 12. Enter/Klick ueberspringt.

const ARENA_SCENE := "res://scenes/arena/arena.tscn"

var _cards: Array[Dictionary] = []
var _card_index := -1
var _card_timer := 0.0
var _title_label: Label
var _name_label: Label
var _hint_label: Label

func _ready() -> void:
	if DisplayServer.get_name() == "headless" or OS.get_environment("PANEM_AUTOSTART") == "1":
		get_tree().change_scene_to_file.call_deferred(ARENA_SCENE)
		return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var background := ColorRect.new()
	background.color = Color(0.05, 0.05, 0.06)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_title_label = _make_label(34, Color(0.75, 0.75, 0.78), -60)
	_name_label = _make_label(48, Color(0.95, 0.8, 0.35), 10)
	_hint_label = _make_label(14, Color(0.5, 0.5, 0.5), 160)
	_hint_label.text = "[Enter] Ueberspringen"

	_build_cards()
	_advance()

func _make_label(font_size: int, color: Color, y_offset: float) -> Label:
	var label := Label.new()
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.anchor_top = 0.5
	label.anchor_bottom = 0.5
	label.offset_top = y_offset
	label.offset_bottom = y_offset + 70
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label

func _build_cards() -> void:
	_cards.append({"title": "PANEM HEUTE", "name": "Die Ernte zu den 74. Hungerspielen", "seconds": 2.6})
	var file := FileAccess.open("res://data/tributes.json", FileAccess.READ)
	var tributes: Array = JSON.parse_string(file.get_as_text()).tributes
	# Distrikte 1-11 als schnelle Montage (beide Namen auf einer Karte)
	for district in range(1, 12):
		var names: Array[String] = []
		for profile in tributes:
			if profile.district == district:
				names.append(profile.name)
		_cards.append({"title": "DISTRIKT %d" % district, "name": " & ".join(names), "seconds": 1.1})
	# Distrikt 12: die dramatische Ziehung
	_cards.append({"title": "DISTRIKT 12", "name": "...", "seconds": 2.0})
	_cards.append({"title": "DISTRIKT 12", "name": "Ash Kohler", "seconds": 2.0})
	_cards.append({"title": "DISTRIKT 12 — und der zweite Tribut ...", "name": "DU.", "seconds": 2.6})
	_cards.append({"title": "", "name": "Moege das Glueck stets mit dir sein.", "seconds": 2.8})

func _process(delta: float) -> void:
	_card_timer -= delta
	if _card_timer <= 0.0:
		_advance()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") \
			or (event is InputEventMouseButton and event.pressed):
		_start_arena()

func _advance() -> void:
	_card_index += 1
	if _card_index >= _cards.size():
		_start_arena()
		return
	var card: Dictionary = _cards[_card_index]
	_title_label.text = card.title
	_name_label.text = card.name
	_card_timer = card.seconds

func _start_arena() -> void:
	set_process(false)
	get_tree().change_scene_to_file(ARENA_SCENE)
