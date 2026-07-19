extends CanvasLayer
## HUD: Countdown, Status (Tag/Uhrzeit/Lebende), Beduerfnis-Balken, Inventar-Slots,
## Interaktions-Hinweis, Meldungs-Log, Himmelsprojektion und Game-Over-Screen.
## Die UI wird komplett in Code aufgebaut.

var player: TributeBase

var _countdown_label: Label
var _status_label: Label
var _hint_label: Label
var _log_box: VBoxContainer
var _bars := {}
var _slot_labels: Array[Label] = []
var _fallen_panel: PanelContainer
var _fallen_label: Label
var _bleed_label: Label
var _venom_label: Label
var _announce_label: Label
var _roster_panel: PanelContainer
var _game_over_rect: ColorRect
var _game_over_title: Label
var _game_over_stats: Label
var _game_over := false

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_countdown_label = _label(root, 72, Color(1, 0.85, 0.3))
	_countdown_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_countdown_label.position = Vector2(-200, 40)
	_countdown_label.size = Vector2(400, 90)
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_status_label = _label(root, 20, Color.WHITE)
	_status_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_status_label.position = Vector2(-420, 16)
	_status_label.size = Vector2(400, 30)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_log_box = VBoxContainer.new()
	_log_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_log_box.position = Vector2(16, 16)
	_log_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_log_box)

	# Beduerfnis-Balken unten links
	var bars_box := VBoxContainer.new()
	bars_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bars_box.position = Vector2(16, -130)
	bars_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bars_box)
	for def in [["Leben", Color(0.8, 0.2, 0.2)], ["Durst", Color(0.25, 0.5, 0.9)], ["Hunger", Color(0.85, 0.55, 0.2)]]:
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = def[0]
		name_label.custom_minimum_size = Vector2(70, 0)
		name_label.add_theme_font_size_override("font_size", 15)
		row.add_child(name_label)
		var bar := ProgressBar.new()
		bar.max_value = 100
		bar.value = 100
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(220, 18)
		var fill := StyleBoxFlat.new()
		fill.bg_color = def[1]
		bar.add_theme_stylebox_override("fill", fill)
		row.add_child(bar)
		bars_box.add_child(row)
		_bars[def[0]] = bar

	# Inventar-Slots unten Mitte
	var slots_box := HBoxContainer.new()
	slots_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	slots_box.position = Vector2(-330, -60)
	slots_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(slots_box)
	for i in 6:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(110, 44)
		var slot_label := Label.new()
		slot_label.text = "%d  —" % (i + 1)
		slot_label.add_theme_font_size_override("font_size", 13)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(slot_label)
		slots_box.add_child(panel)
		_slot_labels.append(slot_label)

	_hint_label = _label(root, 20, Color(1, 1, 0.7))
	_hint_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint_label.position = Vector2(-250, -110)
	_hint_label.size = Vector2(500, 30)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Fadenkreuz
	var crosshair := _label(root, 22, Color(1, 1, 1, 0.6))
	crosshair.text = "•"
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-6, -14)

	_bleed_label = _label(root, 18, Color(0.9, 0.2, 0.2))
	_bleed_label.text = "BLUTUNG — Verband noetig!"
	_bleed_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_bleed_label.position = Vector2(16, -160)
	_bleed_label.visible = false

	_venom_label = _label(root, 18, Color(0.8, 0.7, 0.1))
	_venom_label.text = "VERGIFTET — Jaegerwespen!"
	_venom_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_venom_label.position = Vector2(16, -185)
	_venom_label.visible = false

	# Spielmacher-Ansage (Lautsprecher)
	_announce_label = _label(root, 30, Color(0.95, 0.85, 0.5))
	_announce_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_announce_label.position = Vector2(-400, 150)
	_announce_label.size = Vector2(800, 120)
	_announce_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Himmelsprojektion (abends)
	_fallen_panel = PanelContainer.new()
	_fallen_panel.set_anchors_preset(Control.PRESET_CENTER)
	_fallen_panel.position = Vector2(-260, -160)
	_fallen_panel.visible = false
	root.add_child(_fallen_panel)
	var fallen_box := VBoxContainer.new()
	_fallen_panel.add_child(fallen_box)
	var fallen_title := Label.new()
	fallen_title.text = "— DIE GEFALLENEN —"
	fallen_title.add_theme_font_size_override("font_size", 28)
	fallen_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallen_box.add_child(fallen_title)
	_fallen_label = Label.new()
	_fallen_label.add_theme_font_size_override("font_size", 20)
	_fallen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallen_box.add_child(_fallen_label)

	# Game-Over-Screen
	_game_over_rect = ColorRect.new()
	_game_over_rect.color = Color(0, 0, 0, 0.75)
	_game_over_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_over_rect.visible = false
	root.add_child(_game_over_rect)
	var over_box := VBoxContainer.new()
	over_box.set_anchors_preset(Control.PRESET_CENTER)
	over_box.position = Vector2(-300, -100)
	over_box.custom_minimum_size = Vector2(600, 0)
	_game_over_rect.add_child(over_box)
	_game_over_title = Label.new()
	_game_over_title.add_theme_font_size_override("font_size", 42)
	_game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_box.add_child(_game_over_title)
	_game_over_stats = Label.new()
	_game_over_stats.add_theme_font_size_override("font_size", 22)
	_game_over_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_box.add_child(_game_over_stats)
	var restart_label := Label.new()
	restart_label.text = "\n[Enter] Neue Spiele beginnen"
	restart_label.add_theme_font_size_override("font_size", 18)
	restart_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_box.add_child(restart_label)

	GameManager.countdown_tick.connect(_on_countdown_tick)
	GameManager.phase_changed.connect(_on_phase_changed)
	GameManager.tribute_died.connect(_on_tribute_died)
	GameManager.fallen_projection.connect(_on_fallen_projection)
	GameManager.game_ended.connect(_on_game_ended)
	Gamemaker.announcement.connect(_on_announcement)
	SponsorSystem.gift_incoming.connect(func() -> void:
		_add_log("Ein silberner Fallschirm schwebt herab ..."))
	WeatherSystem.weather_changed.connect(func(_w: int) -> void:
		_add_log("Wetterumschwung: %s" % WeatherSystem.weather_name()))
	_countdown_label.text = str(GameManager.countdown_seconds)

func _label(parent: Control, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

## Tribut-Vorstellung waehrend des Countdowns ("Reaping"-Ersatz)
func show_roster(tributes: Array) -> void:
	if _roster_panel != null:
		_roster_panel.queue_free()
	_roster_panel = PanelContainer.new()
	_roster_panel.anchor_left = 0.5
	_roster_panel.anchor_right = 0.5
	_roster_panel.anchor_top = 0.5
	_roster_panel.anchor_bottom = 0.5
	_roster_panel.offset_left = -300
	_roster_panel.offset_right = 300
	_roster_panel.offset_top = -60
	_roster_panel.offset_bottom = 320
	get_child(0).add_child(_roster_panel)

	var box := VBoxContainer.new()
	_roster_panel.add_child(box)
	var title := Label.new()
	title.text = "— DIE TRIBUTE DER 74. SPIELE —"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	box.add_child(grid)
	for profile in tributes:
		var entry := Label.new()
		var marker := "  ◄ DU" if profile.profil == "spieler" else ""
		entry.text = "D%02d  %s%s" % [profile.district, profile.name, marker]
		entry.add_theme_font_size_override("font_size", 14)
		if profile.profil == "spieler":
			entry.add_theme_color_override("font_color", Color(0.95, 0.8, 0.35))
		grid.add_child(entry)

func bind_player(bound: TributeBase) -> void:
	player = bound
	player.needs_changed.connect(_on_needs_changed)
	player.inventory_changed.connect(_on_inventory_changed)
	player.interact_hint_changed.connect(func(hint: String) -> void: _hint_label.text = hint)

func _process(_delta: float) -> void:
	var hour: float = DayNight.hour
	_status_label.text = "Tag %d   %02d:%02d   %s   %d am Leben" % [
		GameManager.day_number, int(hour), int(fmod(hour, 1.0) * 60),
		WeatherSystem.weather_name(), GameManager.tributes_alive]
	if player != null:
		_bleed_label.visible = player.bleeding_seconds > 0.0
		_venom_label.visible = player.venom_seconds > 0.0

func _input(event: InputEvent) -> void:
	if _game_over and event.is_action_pressed("ui_accept"):
		GameManager.reset()
		get_tree().reload_current_scene()

# --- Signal-Handler ---------------------------------------------------------

func _on_countdown_tick(seconds_left: int) -> void:
	_countdown_label.text = str(seconds_left)

func _on_announcement(text: String) -> void:
	_announce_label.text = "»%s«\n— Die Spielmacher" % text
	get_tree().create_timer(8.0).timeout.connect(func() -> void:
		if _announce_label.text.contains(text):
			_announce_label.text = "")

func _on_phase_changed(new_phase: GameManager.Phase) -> void:
	match new_phase:
		GameManager.Phase.BLOODBATH:
			if _roster_panel != null:
				_roster_panel.queue_free()
				_roster_panel = null
			_countdown_label.text = "DIE SPIELE HABEN BEGONNEN!"
			_countdown_label.add_theme_font_size_override("font_size", 36)
			get_tree().create_timer(4.0).timeout.connect(func() -> void: _countdown_label.text = "")
		GameManager.Phase.FINALE:
			_add_log("Die Spielmacher: Das Finale beginnt!")
		_:
			pass

func _on_tribute_died(tribute_name: String, district: int, _killer: String) -> void:
	_add_log("Kanone — %s (D%d) ist gefallen." % [tribute_name, district])

func _on_fallen_projection(fallen: Array) -> void:
	var names: Array[String] = []
	for entry in fallen:
		names.append("%s (D%d)" % [entry.name, entry.district])
	_fallen_label.text = "\n".join(names)
	_fallen_panel.visible = true
	get_tree().create_timer(8.0).timeout.connect(func() -> void: _fallen_panel.visible = false)

func _on_game_ended(victory: bool, stats: Dictionary) -> void:
	_game_over = true
	_game_over_title.text = "DU BIST SIEGER DER 74. SPIELE!" if victory else "DU BIST GEFALLEN"
	_game_over_title.add_theme_color_override("font_color",
		Color(1, 0.85, 0.3) if victory else Color(0.85, 0.3, 0.3))
	_game_over_stats.text = "Überlebte Tage: %d      Kills: %d      Publikums-Rating: %.0f" % [
		stats.tage, stats.kills, stats.get("rating", 0.0)]
	_game_over_rect.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_needs_changed(health: float, thirst: float, hunger: float) -> void:
	_bars["Leben"].value = health
	_bars["Durst"].value = thirst
	_bars["Hunger"].value = hunger

func _on_inventory_changed(inventory: Array, selected_slot: int) -> void:
	for i in 6:
		if i < inventory.size():
			var label: String = inventory[i].name
			if inventory[i].has("count"):
				label += " (%d)" % inventory[i].count
			_slot_labels[i].text = "%d  %s" % [i + 1, label]
		else:
			_slot_labels[i].text = "%d  —" % (i + 1)
		_slot_labels[i].modulate = Color(1, 0.9, 0.4) if i == selected_slot and i < inventory.size() else Color.WHITE

func _add_log(text: String) -> void:
	var entry := Label.new()
	entry.text = text
	entry.add_theme_font_size_override("font_size", 16)
	_log_box.add_child(entry)
	if _log_box.get_child_count() > 6:
		_log_box.get_child(0).queue_free()
	get_tree().create_timer(10.0).timeout.connect(func() -> void:
		if is_instance_valid(entry):
			entry.queue_free())
