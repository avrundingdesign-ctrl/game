extends Node
## Prozedural synthetisierte Sounds — komplett ohne externe Assets.
## Kanone, Bogen, Treffer, Spotttoelpel-Motiv, Sponsoren-Glocke, Wind-Ambience.

const SAMPLE_RATE := 22050

var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _ambient_timer := 20.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_sounds["kanone"] = _make_cannon()
	_sounds["bogen"] = _make_bow()
	_sounds["treffer"] = _make_hit()
	_sounds["spottoelpel"] = _make_mockingjay()
	_sounds["fallschirm"] = _make_chime()

	for i in 6:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)

	# Dauerhafter Wind
	var wind := AudioStreamPlayer.new()
	wind.stream = _make_wind_loop()
	wind.volume_db = -26.0
	wind.autoplay = true
	add_child(wind)
	wind.play()

	GameManager.tribute_died.connect(func(_n: String, _d: int, _k: String) -> void:
		play("kanone", -4.0))
	GameManager.fallen_projection.connect(func(_fallen: Array) -> void:
		play("spottoelpel", -8.0))
	SponsorSystem.gift_incoming.connect(func() -> void:
		play("fallschirm", -8.0))

func _process(delta: float) -> void:
	# Tagsueber gelegentlich ein ferner Spotttoelpel
	if GameManager.phase == GameManager.Phase.DAY:
		_ambient_timer -= delta
		if _ambient_timer <= 0.0:
			_ambient_timer = _rng.randf_range(35.0, 90.0)
			play("spottoelpel", -20.0)

func play(sound: String, volume_db := -6.0) -> void:
	for player in _players:
		if not player.playing:
			player.stream = _sounds[sound]
			player.volume_db = volume_db
			player.play()
			return

## Nur abspielen, wenn die Quelle in Hoerweite des Spielers ist.
func play_near(sound: String, at: Vector3, volume_db := -6.0) -> void:
	var player_node := get_tree().get_first_node_in_group("player") as Node3D
	if player_node == null:
		return
	var distance := player_node.global_position.distance_to(at)
	if distance > 45.0:
		return
	play(sound, volume_db - distance * 0.4)

# --- Synthese ---------------------------------------------------------------

func _make_wav(samples: PackedFloat32Array, looped := false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	if looped:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = samples.size()
	return wav

func _samples(seconds: float) -> PackedFloat32Array:
	var buffer := PackedFloat32Array()
	buffer.resize(int(seconds * SAMPLE_RATE))
	return buffer

## Dumpfer Kanonenschlag: tiefer Sinus-Sweep + verhallendes Rauschen
func _make_cannon() -> AudioStreamWAV:
	var buffer := _samples(1.4)
	for i in buffer.size():
		var t := float(i) / SAMPLE_RATE
		var freq := lerpf(55.0, 32.0, t / 1.4)
		var boom := sin(TAU * freq * t) * exp(-2.5 * t)
		var rumble := (_rng.randf() * 2.0 - 1.0) * exp(-6.0 * t) * 0.4
		buffer[i] = clampf((boom + rumble) * 0.9, -1.0, 1.0)
	return _make_wav(buffer)

## Bogen: kurzes Schnappen der Sehne
func _make_bow() -> AudioStreamWAV:
	var buffer := _samples(0.18)
	for i in buffer.size():
		var t := float(i) / SAMPLE_RATE
		var twang := sin(TAU * 380.0 * t) * exp(-28.0 * t) * 0.5
		var snap := (_rng.randf() * 2.0 - 1.0) * exp(-45.0 * t) * 0.4
		buffer[i] = twang + snap
	return _make_wav(buffer)

## Treffer: dumpfer Schlag
func _make_hit() -> AudioStreamWAV:
	var buffer := _samples(0.15)
	for i in buffer.size():
		var t := float(i) / SAMPLE_RATE
		buffer[i] = sin(TAU * 170.0 * t) * exp(-30.0 * t) * 0.8 \
			+ (_rng.randf() * 2.0 - 1.0) * exp(-60.0 * t) * 0.2
	return _make_wav(buffer)

## Das Vier-Noten-Motiv des Spotttoelpels (Rues Signal)
func _make_mockingjay() -> AudioStreamWAV:
	var notes := [784.0, 932.3, 880.0, 587.3]  # G5, Bb5, A5, D5
	var note_length := 0.3
	var buffer := _samples(notes.size() * note_length + 0.3)
	for n in notes.size():
		var start := int(n * note_length * SAMPLE_RATE)
		var length := int((note_length + (0.3 if n == notes.size() - 1 else 0.0)) * SAMPLE_RATE)
		for i in length:
			var t := float(i) / SAMPLE_RATE
			var vibrato := 1.0 + 0.004 * sin(TAU * 5.0 * t)
			var envelope := minf(t * 22.0, 1.0) * exp(-3.5 * t)
			var index := start + i
			if index < buffer.size():
				buffer[index] += sin(TAU * notes[n] * vibrato * t) * envelope * 0.5 \
					+ sin(TAU * notes[n] * 2.0 * t) * envelope * 0.12
	return _make_wav(buffer)

## Sanfte Glocke fuer den Sponsoren-Fallschirm
func _make_chime() -> AudioStreamWAV:
	var notes := [1318.5, 1760.0]  # E6, A6
	var buffer := _samples(1.0)
	for n in notes.size():
		var start := int(n * 0.22 * SAMPLE_RATE)
		for i in buffer.size() - start:
			var t := float(i) / SAMPLE_RATE
			buffer[start + i] += sin(TAU * notes[n] * t) * exp(-4.0 * t) * 0.3
	return _make_wav(buffer)

## Leises Windrauschen (geloopt)
func _make_wind_loop() -> AudioStreamWAV:
	var buffer := _samples(4.0)
	var value := 0.0
	for i in buffer.size():
		value += (_rng.randf() * 2.0 - 1.0) * 0.02
		value *= 0.995
		buffer[i] = value * 2.0
	# Enden angleichen, damit der Loop nicht knackt
	var fade := int(0.05 * SAMPLE_RATE)
	for i in fade:
		var factor := float(i) / fade
		buffer[i] *= factor
		buffer[buffer.size() - 1 - i] *= factor
	return _make_wav(buffer, true)
