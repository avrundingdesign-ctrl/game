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
	_sounds["hymne"] = _make_anthem()
	_sounds["beep"] = _make_beep()
	_sounds["gong"] = _make_gong()
	_sounds["knurren"] = _make_growl()
	_sounds["sieg"] = _make_victory()
	_sounds["niederlage"] = _make_defeat()

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
		play("hymne", -8.0))
	SponsorSystem.gift_incoming.connect(func() -> void:
		play("fallschirm", -8.0))
	GameManager.countdown_tick.connect(func(left: int) -> void:
		if left <= 10 and left > 0:
			play("beep", -12.0))
	GameManager.phase_changed.connect(func(new_phase: GameManager.Phase) -> void:
		if new_phase == GameManager.Phase.BLOODBATH:
			play("gong", -4.0))
	GameManager.game_ended.connect(func(victory: bool, _stats: Dictionary) -> void:
		play("sieg" if victory else "niederlage", -6.0))

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

## Feierliche Panem-Hymne (kurze Fanfare zur Himmelsprojektion)
func _make_anthem() -> AudioStreamWAV:
	var notes := [261.6, 329.6, 392.0, 523.3, 392.0, 523.3]  # C4 E4 G4 C5 G4 C5
	var lengths := [0.4, 0.4, 0.4, 0.7, 0.4, 1.1]
	var total := 0.0
	for length in lengths:
		total += length
	var buffer := _samples(total + 0.5)
	var start_time := 0.0
	for n in notes.size():
		var start := int(start_time * SAMPLE_RATE)
		var sustain: float = lengths[n] + 0.4
		for i in int(sustain * SAMPLE_RATE):
			var t := float(i) / SAMPLE_RATE
			var envelope := minf(t * 30.0, 1.0) * exp(-2.2 * t)
			var index := start + i
			if index < buffer.size():
				# Blechblaeser-Anmutung: Grundton + Oktave + Quinte obendrauf
				buffer[index] += (sin(TAU * notes[n] * t) * 0.4 \
					+ sin(TAU * notes[n] * 2.0 * t) * 0.15 \
					+ sin(TAU * notes[n] * 3.0 * t) * 0.08) * envelope
		start_time += lengths[n]
	return _make_wav(buffer)

func _make_beep() -> AudioStreamWAV:
	var buffer := _samples(0.09)
	for i in buffer.size():
		var t := float(i) / SAMPLE_RATE
		buffer[i] = sin(TAU * 880.0 * t) * minf(t * 60.0, 1.0) * exp(-18.0 * t) * 0.5
	return _make_wav(buffer)

## Tiefer Gong zum Start des Blutbads
func _make_gong() -> AudioStreamWAV:
	var buffer := _samples(2.0)
	for i in buffer.size():
		var t := float(i) / SAMPLE_RATE
		buffer[i] = (sin(TAU * 165.0 * t) * 0.5 + sin(TAU * 220.7 * t) * 0.3 \
			+ sin(TAU * 329.0 * t) * 0.15) * exp(-1.8 * t)
	return _make_wav(buffer)

## Wolfsmutt-Knurren
func _make_growl() -> AudioStreamWAV:
	var buffer := _samples(0.6)
	for i in buffer.size():
		var t := float(i) / SAMPLE_RATE
		var rasp := 1.0 + 0.5 * sin(TAU * 28.0 * t)
		buffer[i] = (fmod(t * 82.0, 1.0) * 2.0 - 1.0) * 0.35 * rasp * minf(t * 12.0, 1.0) * exp(-2.5 * t) \
			+ (_rng.randf() * 2.0 - 1.0) * 0.1 * exp(-3.0 * t)
	return _make_wav(buffer)

## Sieg-Fanfare (aufsteigend, hell)
func _make_victory() -> AudioStreamWAV:
	var notes := [392.0, 523.3, 659.3, 784.0]  # G4 C5 E5 G5
	var buffer := _samples(2.6)
	for n in notes.size():
		var start := int(n * 0.28 * SAMPLE_RATE)
		var sustain := 0.5 if n < notes.size() - 1 else 1.4
		for i in int(sustain * SAMPLE_RATE):
			var t := float(i) / SAMPLE_RATE
			var index := start + i
			if index < buffer.size():
				buffer[index] += (sin(TAU * notes[n] * t) * 0.35 \
					+ sin(TAU * notes[n] * 2.0 * t) * 0.12) * minf(t * 40.0, 1.0) * exp(-2.0 * t)
	return _make_wav(buffer)

## Niederlage (fallende Moll-Linie, dunkel)
func _make_defeat() -> AudioStreamWAV:
	var notes := [220.0, 174.6, 146.8]  # A3 F3 D3
	var buffer := _samples(2.8)
	for n in notes.size():
		var start := int(n * 0.55 * SAMPLE_RATE)
		for i in int(1.4 * SAMPLE_RATE):
			var t := float(i) / SAMPLE_RATE
			var index := start + i
			if index < buffer.size():
				buffer[index] += sin(TAU * notes[n] * t) * 0.4 * minf(t * 15.0, 1.0) * exp(-1.6 * t)
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
