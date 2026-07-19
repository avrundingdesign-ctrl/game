extends Node
## Tag/Nacht-Zyklus: dreht die Sonne (DirectionalLight3D in Gruppe "sun")
## und meldet Sonnenauf-/untergang an den GameManager.

signal time_changed(hour: float)

## Ein Arena-Tag in Echtzeit-Sekunden (Design: 8-12 Minuten).
@export var day_length_seconds := 600.0

var hour := 8.0  # Start am Morgen
var _was_day := true

func _ready() -> void:
	if OS.get_environment("PANEM_FAST") == "1":
		day_length_seconds = 60.0

func _process(delta: float) -> void:
	if GameManager.phase in [GameManager.Phase.COUNTDOWN, GameManager.Phase.GAME_OVER]:
		return
	hour = fmod(hour + delta * 24.0 / day_length_seconds, 24.0)
	time_changed.emit(hour)
	_update_sun()
	var is_day := hour >= 6.0 and hour < 20.0
	if is_day and not _was_day:
		GameManager.on_sunrise()
	elif not is_day and _was_day:
		GameManager.on_sunset()
	_was_day = is_day

func _update_sun() -> void:
	# 6 Uhr = Horizont Ost, 12 Uhr = Zenit, 20 Uhr = Horizont West
	var t := (hour - 6.0) / 14.0
	var sun := get_tree().get_first_node_in_group("sun") as DirectionalLight3D
	if sun != null:
		sun.rotation_degrees.x = -lerp(0.0, 180.0, clamp(t, 0.0, 1.0))
		sun.visible = t > 0.01 and t < 0.99
		var elevation := sin(clamp(t, 0.0, 1.0) * PI)
		sun.light_energy = clamp(elevation * 1.4, 0.05, 1.4)
		# Warmes Licht bei Sonnenauf-/untergang
		sun.light_color = Color(1.0, 0.55, 0.3).lerp(Color(1.0, 0.98, 0.92), clampf(elevation * 1.6, 0.0, 1.0))

	var moon := get_tree().get_first_node_in_group("moon") as DirectionalLight3D
	if moon != null:
		var night_hour := fmod(hour - 20.0 + 24.0, 24.0)  # 20 Uhr -> 0, 6 Uhr -> 10
		var night_t := clampf(night_hour / 10.0, 0.0, 1.0)
		moon.rotation_degrees.x = -lerp(10.0, 170.0, night_t)
		moon.light_energy = 0.25 * sin(night_t * PI)
		moon.visible = moon.light_energy > 0.01
