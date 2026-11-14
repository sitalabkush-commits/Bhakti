extends Control
# All graphics are drawn in code. mode: 0 crossroads, 1 worldly, 2 hell, 3 animal, 4 devotion, 5 heaven
var mode := 0
var t := 0.0
var jump := 0.0
var kortal := 0.0
var khole := 0.0
var kirtan := false
var sin_frac := 0.0
var merit_frac := 0.0
var need_frac := 0.4
var animal_idx := 0
var parts: Array = []   # [x, y, vx, vy, life, kind]

func _process(dt: float) -> void:
	t += dt
	var w := size.x
	var h := size.y
	if mode == 4 and kirtan and randf() < dt * (6.0 + 20.0 * jump):
		parts.append([randf() * w, -10.0, randf_range(-20, 20), randf_range(50, 110), 6.0, 0])   # petals
	if mode == 4 and kirtan and randf() < dt * (10.0 + 40.0 * jump + 30.0 * (kortal + khole)):
		parts.append([w * 0.84 + randf_range(-30, 30), h * 0.9, randf_range(-15, 15), randf_range(-120, -60), 1.4, 1])  # punya sparks
	if mode == 2 and randf() < dt * 30.0:
		parts.append([randf() * w, h, randf_range(-20, 20), randf_range(-160, -80), 2.0, 2])   # embers
	if mode == 1 and randf() < dt * 8.0:
		parts.append([randf() * w, -10.0, 0.0, randf_range(120, 200), 4.0, 3])                 # falling coins
	for p in parts:
		p[0] += p[2] * dt
		p[1] += p[3] * dt
		p[4] -= dt
	parts = parts.filter(func(p): return p[4] > 0.0)
	queue_redraw()

func _grad(top: Color, bot: Color) -> void:
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), size, Vector2(0, size.y)]),
		PackedColorArray([top, top, bot, bot]))

func _glow(c: Vector2, r: float, col: Color) -> void:
	for i in range(8):
		var k := float(i) / 8.0
		draw_circle(c, r * (1.0 - k * 0.8), Color(col.r, col.g, col.b, 0.07 + k * 0.05))

func _draw() -> void:
	var w := size.x
	var h := size.y
	var gy := h * 0.78   # ground line
	match mode:
		0:
			_grad(Color(0.12, 0.1, 0.35), Color(0.95, 0.55, 0.4))
			_glow(Vector2(w * 0.5, gy - 20), 220, Color(1, 0.8, 0.5))
			draw_rect(Rect2(0, gy, w, h - gy), Color(0.15, 0.1, 0.12))
			# forked road
			draw_colored_polygon(PackedVector2Array([Vector2(w * 0.42, h), Vector2(w * 0.58, h), Vector2(w * 0.52, gy), Vector2(w * 0.48, gy)]), Color(0.45, 0.35, 0.3))
			draw_colored_polygon(PackedVector2Array([Vector2(w * 0.48, gy), Vector2(w * 0.52, gy), Vector2(w * 0.95, gy - 90), Vector2(w * 0.88, gy - 95)]), Color(0.5, 0.4, 0.3))
			draw_colored_polygon(PackedVector2Array([Vector2(w * 0.48, gy), Vector2(w * 0.52, gy), Vector2(w * 0.12, gy - 90), Vector2(w * 0.05, gy - 95)]), Color(0.3, 0.22, 0.25))
			_glow(Vector2(w * 0.9, gy - 100), 80, Color(1, 0.85, 0.3))   # golden right path
			_person(w * 0.5, h - 20, 1.3, Color(1, 0.6, 0.15), 0.0, 0.0)
		1:
			_grad(Color(0.08, 0.06, 0.1), Color(0.4, 0.15, 0.18))
			for i in range(5):
				draw_circle(Vector2(fmod(i * 170.0 + t * 12.0, w + 100) - 50, 80 + i * 22), 60 + i * 8, Color(0.2, 0.2, 0.25, 0.5))
			draw_rect(Rect2(0, gy, w, h - gy), Color(0.1, 0.07, 0.08))
			_person(w * 0.5, gy + 60, 1.4, Color(0.45, 0.4, 0.5), 0.0, t)
			_bucket(w * 0.82, gy + 60, 90, 120, sin_frac, Color(0.3, 0.05, 0.08), Color(0.8, 0.1, 0.1), "পাপ")
		2:
			_grad(Color(0.15, 0.0, 0.0), Color(0.95, 0.3, 0.05))
			for i in range(14):
				var fx := i * w / 13.0
				var fh := 120.0 + 60.0 * sin(t * 4.0 + i * 1.7)
				draw_colored_polygon(PackedVector2Array([Vector2(fx - 45, h), Vector2(fx, h - fh), Vector2(fx + 45, h)]), Color(1, 0.45 + 0.3 * sin(t * 6.0 + i), 0.05, 0.85))
			_person(w * 0.5, h - 40, 1.2, Color(0.2, 0.05, 0.05), 0.0, t * 3.0)
		3:
			_grad(Color(0.45, 0.65, 0.9), Color(0.8, 0.9, 0.7))
			draw_rect(Rect2(0, gy, w, h - gy), Color(0.3, 0.55, 0.25))
			_animal(Vector2(w * 0.5, gy + 50), animal_idx)
		4:
			_devotion(w, h, gy)
		5:
			_heaven(w, h, gy)
	for p in parts:
		var a: float = clampf(p[4], 0.0, 1.0)
		match p[5]:
			0: draw_circle(Vector2(p[0], p[1]), 5, Color(1, 0.6 + 0.3 * sin(p[0]), 0.7, a))
			1: draw_circle(Vector2(p[0], p[1]), 4, Color(1, 0.9, 0.3, a))
			2: draw_circle(Vector2(p[0], p[1]), 3, Color(1, 0.7, 0.2, a))
			3: draw_circle(Vector2(p[0], p[1]), 6, Color(1, 0.85, 0.2, 0.9))

func _devotion(w: float, h: float, gy: float) -> void:
	_grad(Color(0.3, 0.08, 0.45), Color(1.0, 0.72, 0.25))
	var sun := Vector2(w * 0.5, gy - 110)
	_glow(sun, 300, Color(1, 0.85, 0.4))
	draw_circle(sun, 70, Color(1, 0.93, 0.6))
	for i in range(16):   # rotating rays, faster when kirtan is strong
		var ang := t * (0.2 + jump * 0.6) + i * TAU / 16.0
		draw_line(sun + Vector2(cos(ang), sin(ang)) * 90, sun + Vector2(cos(ang), sin(ang)) * (180 + 60 * jump), Color(1, 0.9, 0.5, 0.25), 6)
	# distant temple
	var tc := Color(0.25, 0.08, 0.3)
	draw_rect(Rect2(w * 0.38, gy - 120, w * 0.24, 120), tc)
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.36, gy - 120), Vector2(w * 0.5, gy - 230), Vector2(w * 0.64, gy - 120)]), tc)
	draw_line(Vector2(w * 0.5, gy - 230), Vector2(w * 0.5, gy - 270), tc, 4)
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.5, gy - 270), Vector2(w * 0.5 + 30, gy - 258 + sin(t * 4) * 4), Vector2(w * 0.5, gy - 246)]), Color(1, 0.5, 0.1))
	draw_rect(Rect2(0, gy, w, h - gy), Color(0.22, 0.08, 0.2))
	var drive := t * (30.0 + 120.0 * jump) if kirtan else 0.0
	# procession: back row small, front row large
	for row in range(2):
		var sc := 0.7 + row * 0.35
		var spacing := 90.0 * sc
		var cnt := int(w / spacing) + 3
		for i in range(cnt):
			var x := fposmod(i * spacing - drive * sc, w + spacing * 2) - spacing
			var by := gy + 25 + row * 60 + 40 * sc
			var amp := (0.3 + jump) if kirtan else 0.0
			var col := Color(1, 0.55 + 0.2 * (i % 3) / 2.0, 0.2) if i % 2 == 0 else Color(0.97, 0.95, 0.9)
			_person(x, by - absf(sin(t * 6.0 + i * 0.9)) * 26.0 * amp * sc, sc, col, amp, t * 6.0 + i)
	# hero
	var hy := gy + 150 - jump * 170.0 - (absf(sin(t * 9.0)) * 18.0 if kirtan else 0.0)
	_glow(Vector2(w * 0.4, hy - 60), 90, Color(1, 0.9, 0.5))
	_person(w * 0.4, hy, 1.6, Color(1, 0.85, 0.3), 1.0 if kirtan else 0.2, t * 9.0)
	if kortal > 0.0:
		var cl := sin(t * 28.0) * 14.0
		draw_circle(Vector2(w * 0.4 - 28 - cl, hy - 175), 20, Color(1, 0.85, 0.2))
		draw_circle(Vector2(w * 0.4 + 28 + cl, hy - 175), 20, Color(1, 0.85, 0.2))
	if khole > 0.0:
		draw_circle(Vector2(w * 0.4, hy - 60), 26, Color(0.7, 0.3, 0.15))
		draw_arc(Vector2(w * 0.4, hy - 60), 26, 0, TAU, 24, Color(0.2, 0.1, 0.05), 4)
	# sound rings
	if kirtan:
		for i in range(3):
			var r := fposmod(t * 90.0 + i * 70.0, 210.0)
			draw_arc(Vector2(w * 0.4, hy - 100), r, 0, TAU, 40, Color(1, 0.95, 0.6, 1.0 - r / 210.0), 3)
	# buckets: sin (draining) and punya (filling)
	_bucket(w * 0.12, h - 25, 90, 150, sin_frac, Color(0.25, 0.1, 0.12), Color(0.55, 0.1, 0.15), "পাপ")
	_bucket(w * 0.84, h - 25, 110, 190, merit_frac, Color(0.5, 0.3, 0.05), Color(1, 0.8, 0.15), "পুণ্য", need_frac)

func _bucket(cx: float, by: float, bw: float, bh: float, frac: float, rim: Color, liq: Color, label: String, mark := -1.0) -> void:
	var tl := Vector2(cx - bw / 2, by - bh)
	var tr := Vector2(cx + bw / 2, by - bh)
	var br := Vector2(cx + bw * 0.35, by)
	var bl := Vector2(cx - bw * 0.35, by)
	draw_colored_polygon(PackedVector2Array([tl, tr, br, bl]), Color(0.1, 0.1, 0.12, 0.55))
	var f: float = clampf(frac, 0.0, 1.0)
	if f > 0.001:
		var ly := by - bh * f
		var k := (by - ly) / bh
		var lx := lerpf(cx - bw * 0.35, cx - bw / 2, k)
		var rx := lerpf(cx + bw * 0.35, cx + bw / 2, k)
		var pts := PackedVector2Array([Vector2(lx, ly)])
		for i in range(9):
			pts.append(Vector2(lerpf(lx, rx, i / 8.0), ly + sin(t * 3.0 + i * 0.9) * 4.0))
		pts.append(br)
		pts.append(bl)
		draw_colored_polygon(pts, liq)
		_glow(Vector2(cx, ly), bw * 0.9, Color(liq.r, liq.g, liq.b))
	draw_line(tl, bl, rim, 6)
	draw_line(tr, br, rim, 6)
	draw_line(bl, br, rim, 6)
	draw_line(tl, tr, rim.lightened(0.3), 6)
	draw_arc(Vector2(cx, tl.y), bw / 2 + 4, PI, TAU, 20, rim.lightened(0.2), 4)
	if mark >= 0.0:
		var my := by - bh * mark
		draw_line(Vector2(cx - bw / 2 - 14, my), Vector2(cx + bw / 2 + 14, my), Color(1, 1, 1, 0.9), 3)
	draw_string(ThemeDB.fallback_font, Vector2(cx - 60, by + 4 - bh - 28), label, HORIZONTAL_ALIGNMENT_CENTER, 120, 28, Color(1, 1, 1))

func _person(x: float, y: float, s: float, col: Color, amp: float, ph: float) -> void:
	var dark := col.darkened(0.45)
	var sway := sin(ph) * 10.0 * amp * s
	draw_circle(Vector2(x + sway * 0.3, y - 88 * s), 13 * s, Color(0.85, 0.6, 0.45))                       # head
	draw_colored_polygon(PackedVector2Array([Vector2(x - 17 * s, y - 72 * s), Vector2(x + 17 * s, y - 72 * s), Vector2(x + 13 * s, y), Vector2(x - 13 * s, y)]), col)
	var arm := -PI / 2 + sin(ph * 1.3) * 0.5 * amp   # arms raised when amp high
	var down := PI / 2 - 0.3
	var a1: float = lerpf(down, arm, clampf(amp, 0.0, 1.0))
	var a2: float = lerpf(PI - down, PI - arm, clampf(amp, 0.0, 1.0))
	draw_line(Vector2(x - 15 * s, y - 66 * s), Vector2(x - 15 * s, y - 66 * s) + Vector2(cos(a2), sin(a2)) * 44 * s, dark, 7 * s)
	draw_line(Vector2(x + 15 * s, y - 66 * s), Vector2(x + 15 * s, y - 66 * s) + Vector2(cos(a1), sin(a1)) * 44 * s, dark, 7 * s)

func _animal(c: Vector2, idx: int) -> void:
	var col: Color = [Color(0.55, 0.35, 0.2), Color(0.9, 0.7, 0.4), Color(0.9, 0.9, 0.85)][idx % 3]
	var bob := sin(t * 4.0) * 5.0
	draw_circle(c + Vector2(0, -40 + bob), 55, col)                       # body
	draw_circle(c + Vector2(60, -85 + bob), 32, col)                      # head
	draw_circle(c + Vector2(70, -90 + bob), 4, Color.BLACK)
	var ear := PackedVector2Array([c + Vector2(45, -105 + bob), c + Vector2(50, -140 + bob), c + Vector2(68, -108 + bob)])
	if idx == 2:
		ear = PackedVector2Array([c + Vector2(45, -105 + bob), c + Vector2(40, -135 + bob), c + Vector2(60, -112 + bob)])
		draw_line(c + Vector2(70, -112 + bob), c + Vector2(80, -145 + bob), Color(0.4, 0.3, 0.2), 5)   # horn
	draw_colored_polygon(ear, col.darkened(0.2))
	for lx in [-30.0, 25.0]:
		draw_rect(Rect2(c.x + lx, c.y + bob * 0.2, 12, 40), col.darkened(0.25))

func _heaven(w: float, h: float, gy: float) -> void:
	_grad(Color(0.7, 0.75, 1.0), Color(1.0, 0.97, 0.8))
	_glow(Vector2(w * 0.5, h * 0.35), 320, Color(1, 0.95, 0.6))
	for i in range(6):
		draw_circle(Vector2(fposmod(i * 190.0 + t * 15.0, w + 200) - 100, gy + (i % 3) * 30), 50 + (i % 2) * 20, Color(1, 1, 1, 0.7))
	var gc := Color(1, 0.85, 0.3)
	draw_rect(Rect2(w * 0.25, h * 0.2, 26, gy - h * 0.2), gc)
	draw_rect(Rect2(w * 0.75 - 26, h * 0.2, 26, gy - h * 0.2), gc)
	draw_arc(Vector2(w * 0.5, h * 0.2), w * 0.25, PI, TAU, 40, gc, 26)
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.28, gy), Vector2(w * 0.72, gy), Vector2(w * 0.72, gy + 20), Vector2(w * 0.28, gy + 20)]), Color(1, 1, 1, 0.8))
	_person(w * 0.2, gy + 20, 1.5, Color(0.95, 0.95, 1), 0.0, t)    # guards
	_person(w * 0.8, gy + 20, 1.5, Color(0.95, 0.95, 1), 0.0, t)
	# merit tanker rolling in; size grows with merit
	var tx := fposmod(t * 140.0, w + 400) - 300
	var ts: float = 0.6 + clampf(merit_frac, 0, 1) * 0.8
	var ty := gy + 70
	draw_rect(Rect2(tx, ty - 70 * ts, 170 * ts, 60 * ts), Color(0.9, 0.6, 0.1))                         # cabin+bed
	draw_rect(Rect2(tx + 120 * ts, ty - 100 * ts, 60 * ts, 50 * ts), Color(0.8, 0.45, 0.1))
	draw_rect(Rect2(tx - 130 * ts, ty - 90 * ts, 140 * ts, 70 * ts), Color(1, 0.8, 0.2))             # tank
	draw_circle(Vector2(tx - 130 * ts, ty - 55 * ts), 35 * ts, Color(1, 0.8, 0.2))
	draw_circle(Vector2(tx + 10 * ts, ty - 55 * ts), 35 * ts, Color(1, 0.8, 0.2))
	draw_string(ThemeDB.fallback_font, Vector2(tx - 100 * ts, ty - 45 * ts), "পুণ্য", HORIZONTAL_ALIGNMENT_LEFT, -1, int(26 * ts), Color(0.5, 0.2, 0))
	for wx in [-90.0, -20.0, 60.0, 130.0]:
		draw_circle(Vector2(tx + wx * ts, ty - 8 * ts), 16 * ts, Color(0.15, 0.1, 0.1))
	_glow(Vector2(tx, ty - 60 * ts), 160 * ts, Color(1, 0.9, 0.4))
