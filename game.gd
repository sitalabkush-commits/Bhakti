extends Control
# State machine: CROSSROADS -> (WORLDLY -> HELL -> ANIMAL ->) back, or DEVOTION -> HEAVEN
enum S { CROSSROADS, WORLDLY, HELL, ANIMAL, DEVOTION, HEAVEN }

const ANIMALS := ["কুকুর", "বিড়াল", "ছাগল"]
const SIN_LIMIT := 100.0
const DEVOTION_YEARS := 10.0
const MERIT_NEEDED := 60.0
const MERIT_CAP := 150.0

var state: S = S.CROSSROADS
var karma := 0.0
var bucket := 0.0
var merit := 0.0
var years := 0.0
var jump := 0.0
var kortal := 0.0
var khole := 0.0
var kirtan := false
var stage_time := 0.0
var animal_idx := 0
var rebirths := 0

var title: Label
var info: Label
var stage: Control
var box: VBoxContainer
var p_drone: AudioStreamPlayer
var p_khole: AudioStreamPlayer
var p_kartal: AudioStreamPlayer
var p_vocal: AudioStreamPlayer

func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	title = _label(root, 42)
	stage = Control.new()
	stage.set_script(load("res://stage.gd"))
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.clip_contents = true
	root.add_child(stage)
	info = _label(root, 28)
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	root.add_child(box)
	_setup_audio()
	_enter(S.CROSSROADS)

# ---------- audio ----------
func _make_player(path: String, loop: bool) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.volume_db = -80.0
	add_child(p)
	if ResourceLoader.exists(path):
		var s = load(path)
		if s is AudioStreamWAV and loop:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_begin = 0
			s.loop_end = int(s.get_length() * s.mix_rate)
		elif s is AudioStreamOggVorbis:
			s.loop = loop
		p.stream = s
	return p

func _setup_audio() -> void:
	p_drone = _make_player("res://assets/drone.wav", true)
	p_khole = _make_player("res://assets/khole.wav", true)
	p_kartal = _make_player("res://assets/kartal.wav", true)
	# Optional: put your own real kirtan recording at assets/kirtan.ogg and it plays on top.
	p_vocal = _make_player("res://assets/kirtan.ogg", true)

func _kirtan(on: bool) -> void:
	kirtan = on
	for p in [p_drone, p_khole, p_kartal, p_vocal]:
		if on and p.stream and not p.playing:
			p.play()
		elif not on:
			p.stop()

func _mix(dt: float) -> void:
	if not kirtan:
		return
	var vol := 0.5 + jump * 0.5
	p_drone.volume_db = lerpf(p_drone.volume_db, -12.0, dt * 3.0)
	p_khole.volume_db = lerpf(p_khole.volume_db, -8.0 if khole > 0.0 else -16.0, dt * 8.0)
	p_kartal.volume_db = lerpf(p_kartal.volume_db, -6.0 if kortal > 0.0 else -22.0, dt * 8.0)
	p_vocal.volume_db = lerpf(p_vocal.volume_db, linear_to_db(vol) - 4.0, dt * 3.0)

# ---------- ui helpers ----------
func _label(parent: Node, fs: int) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fs)
	parent.add_child(l)
	return l

func _button(parent: Node, text: String, cb: Callable, down_mode := false, h := 110) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, h)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 32)
	if down_mode:
		b.button_down.connect(cb)
	else:
		b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _tap(kind: String) -> void:
	if not kirtan:
		_kirtan(true)   # first press of any switch starts the kirtan
	match kind:
		"jump": jump = minf(1.0, jump + 0.18)
		"kortal": kortal = 2.0
		"khole": khole = 2.0
	Input.vibrate_handheld(15)

# ---------- state machine ----------
func _enter(s: S) -> void:
	state = s
	stage_time = 0.0
	for c in box.get_children():
		c.queue_free()
	stage.mode = int(s)
	if s != S.DEVOTION:
		_kirtan(false)
	match s:
		S.CROSSROADS:
			title.text = "চৌরাস্তা (মানব জন্ম #%d)" % (rebirths + 1)
			info.text = "পথ বেছে নাও"
			karma = 0.0; bucket = 0.0; merit = 0.0; years = 0.0; jump = 0.0
			_button(box, "ভক্তির পথ", func(): _enter(S.DEVOTION))
			_button(box, "ভক্তি ছাড়া পথ", func(): _enter(S.WORLDLY))
		S.WORLDLY:
			title.text = "মায়ার সংসার"
			_button(box, "আরও লোভ করো", func(): karma += 4.0, true)
		S.HELL:
			title.text = "নরক"
			info.text = "পাপের ফল ভোগ..."
		S.ANIMAL:
			animal_idx = 0
			title.text = "পশু জন্ম: %s" % ANIMALS[0]
			info.text = "মৃত্যু ও পুনর্জন্মের চক্র..."
		S.DEVOTION:
			title.text = "ভক্তির মিছিল"
			bucket = 60.0
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			box.add_child(_wrap_big())
			box.add_child(row)
			_button(row, "কর্তাল", func(): _tap("kortal"), true, 90)
			_button(row, "খোল", func(): _tap("khole"), true, 90)
		S.HEAVEN:
			title.text = "স্বর্গের দরজা"
			var ok := merit >= MERIT_NEEDED
			info.text = "পুণ্যের ট্যাঙ্কার: %d / %d\n%s" % [merit, MERIT_NEEDED,
				"প্রহরী: প্রবেশ করুন, নারায়ণের কাছে স্বাগতম!" if ok else "প্রহরী: পুণ্য কম! আবার জন্ম নাও।"]
			if not ok:
				rebirths += 1
			_button(box, "শুরু থেকে খেলো" if ok else "পুনর্জন্ম", func():
				if ok: rebirths = 0
				_enter(S.CROSSROADS))

func _wrap_big() -> Control:
	var b := Button.new()
	b.text = "নাচার সুইচ (ভক্তি)"
	b.custom_minimum_size = Vector2(0, 150)
	b.add_theme_font_size_override("font_size", 38)
	b.button_down.connect(func(): _tap("jump"))
	return b

func _process(dt: float) -> void:
	stage_time += dt
	match state:
		S.WORLDLY:
			karma += dt * 3.0
			info.text = "পাপ: %d / %d" % [karma, SIN_LIMIT]
			if karma >= SIN_LIMIT:
				_enter(S.HELL)
		S.HELL:
			if stage_time > 4.0:
				_enter(S.ANIMAL)
		S.ANIMAL:
			if stage_time > 3.0:
				stage_time = 0.0
				animal_idx += 1
				if animal_idx >= ANIMALS.size():
					rebirths += 1
					_enter(S.CROSSROADS)
				else:
					title.text = "পশু জন্ম: %s" % ANIMALS[animal_idx]
		S.DEVOTION:
			jump = maxf(0.0, jump - dt * 0.6)
			kortal = maxf(0.0, kortal - dt)
			khole = maxf(0.0, khole - dt)
			if kirtan:
				var mult := 1.0 + (1.0 if kortal > 0.0 else 0.0) + (1.0 if khole > 0.0 else 0.0)
				var energy := 0.3 + jump
				bucket = maxf(0.0, bucket - dt * 4.0 * mult * energy)
				merit += dt * 2.0 * mult * energy
				years += dt * 0.25 * energy
				info.text = "বছর: %.1f / %d | পুণ্য: %d | গুণক x%d" % [years, DEVOTION_YEARS, merit, mult]
				if years >= DEVOTION_YEARS:
					_enter(S.HEAVEN)
			else:
				info.text = "নাচার সুইচ টিপে কীর্তন শুরু করো"
	_mix(dt)
	stage.jump = jump
	stage.kortal = kortal
	stage.khole = khole
	stage.kirtan = kirtan
	stage.sin_frac = karma / SIN_LIMIT if state == S.WORLDLY else bucket / 100.0
	stage.merit_frac = merit / MERIT_CAP
	stage.need_frac = MERIT_NEEDED / MERIT_CAP
	stage.animal_idx = animal_idx
