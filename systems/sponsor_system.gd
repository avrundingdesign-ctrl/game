extends Node
## Sponsoren: Ein verstecktes Publikums-Rating entscheidet, ob der Mentor
## in kritischen Momenten ein Fallschirm-Geschenk schickt.
## Geschenke werden mit jedem Mal teurer (steigende Schwelle).

signal gift_incoming()

var rating := 40.0
var _gift_threshold := 50.0
var _player: TributeBase = null
var _cooldown := 0.0

func reset() -> void:
	rating = 40.0
	_gift_threshold = 50.0
	_player = null
	_cooldown = 0.0

func bind_player(player: TributeBase) -> void:
	_player = player
	rating = 40.0 + float(player.stats.charisma) * 2.0
	GameManager.tribute_died.connect(_on_tribute_died)

func _on_tribute_died(_name: String, _district: int, killer: String) -> void:
	if _player != null and killer == _player.tribute_name:
		rating = minf(100.0, rating + 15.0)  # Das Publikum liebt Action

func _process(delta: float) -> void:
	if _player == null or not _player.alive:
		return
	if GameManager.phase in [GameManager.Phase.COUNTDOWN, GameManager.Phase.GAME_OVER]:
		return
	var day := DayNight.day_length_seconds
	# Ueberleben bringt langsam Sympathie, Untaetigkeit kostet mehr (implizit ausgeglichen)
	rating = clampf(rating + 5.0 / day * delta, 0.0, 100.0)
	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown > 0.0:
		return

	var needed_item := _critical_need()
	if needed_item != "" and rating >= _gift_threshold:
		_send_gift(needed_item)

## Was braucht der Spieler JETZT am dringendsten?
func _critical_need() -> String:
	if _player.bleeding_seconds > 3.0 and not _has_type("medizin"):
		return "verband"
	if _player.health < 35.0 and not _has_type("medizin"):
		return "medikit"
	if _player.thirst < 15.0 and not _has_type("wasser"):
		return "wasserflasche"
	if _player.hunger < 15.0 and not _has_type("essen"):
		return "brot"
	return ""

func _has_type(type: String) -> bool:
	for item in _player.inventory:
		if item.type == type:
			return true
	return false

func _send_gift(item_id: String) -> void:
	rating -= 20.0
	_gift_threshold = minf(90.0, _gift_threshold + 12.0)  # naechstes Geschenk teurer
	_cooldown = DayNight.day_length_seconds * 0.25  # fruehestens 6 Arena-Stunden spaeter
	gift_incoming.emit()
	print("[Sponsor] Geschenk unterwegs: %s (Rating jetzt %.0f)" % [item_id, rating])

	# Fallschirm: schwebt neben dem Spieler ein
	var ground := _player.global_position.y
	var pickup := LootPickup.create(item_id, _player.global_position + Vector3(2, 12, 2))
	pickup.item["name"] = "%s (Sponsor!)" % pickup.item.name
	_player.get_parent().add_child(pickup)
	var tween := pickup.create_tween()
	tween.tween_property(pickup, "position:y", ground + 0.6, 6.0).set_ease(Tween.EASE_OUT)
