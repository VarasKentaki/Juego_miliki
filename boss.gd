class_name Boss extends Node3D
var g
var hp = 800.0; var st = "idle"; var t = 2.6; var an = ""; var w = 1.0; var hit = false; var ph = 1; var cb = false; var face = 0.0; var flash = 0.0
var galileo = false
var slide = 0.0; var recoil = 0.0; var step_t = 0.0; var pose_x = null
var arm: Node3D; var body: Node3D; var club: StandardMaterial3D; var robe: StandardMaterial3D; var tele = {}; var galileo_body: Node3D; var galileo_arm: Node3D; var galileo_club: StandardMaterial3D

func _ready():
	var m = Models.fuvu(); body = m.root; arm = m.arm; club = m.club; robe = m.robe; add_child(body)
	var gm = Models.galileo(); galileo_body = gm.root; galileo_arm = gm.arm; galileo_club = gm.club; galileo_body.visible = false; add_child(galileo_body)
	for n in Cfg.A:
		var a = Cfg.A[n]; var mi = MeshInstance3D.new()
		mi.mesh = Models.sector(a.get("tR", a.R), deg_to_rad(a.get("tg", a.g)))
		mi.material_override = Models.flat(Color(.85, .1, .1, 0)); mi.visible = false; mi.position.y = .06; add_child(mi); tele[n] = mi
	for n in Cfg.GA:
		var a = Cfg.GA[n]; var mi = MeshInstance3D.new()
		mi.mesh = Models.sector(a.get("tR", a.R), deg_to_rad(a.get("tg", a.g)))
		mi.material_override = Models.flat(Color(.7, .3, 1.0, 0)); mi.visible = false; mi.position.y = .06; add_child(mi); tele[n] = mi

func reset():
	galileo = false; hp = Cfg.B.hp; st = "idle"; t = 2.6; ph = 1; an = ""; cb = false; face = 0.0; position = Vector3(0, 0, -3)
	pose_x = null; body.visible = true; galileo_body.visible = false; body.rotation.z = 0; body.position.y = 0; robe.albedo_color = Color(.12, .23, .17); robe.emission_enabled = false

func begin_galileo():
	galileo = true; hp = Cfg.G.hp; st = "trans"; t = 3.2; ph = 1; an = ""; cb = false; face = PI; position = Vector3(0, 0, -3)
	body.visible = false; galileo_body.visible = true
	g.say("«¡No toques mi pitulín! Así llamo al pepino de mi huerto.»")
	g.sfx("bell")

func stagger(d):
	if st != "dead" and st != "trans":
		st = "rec"; an = ""; t = d; slide = 0.0

func turn(c, tg, r): return c + clamp(angle_difference(c, tg), -r, r)

func move(d):
	position += Vector3(sin(face), 0, cos(face)) * d
	var h = Vector2(position.x, position.z).length()
	if h > Cfg.ARENA:
		position.x *= Cfg.ARENA / h; position.z *= Cfg.ARENA / h

func pick(d):
	if galileo:
		var gl = ["embestida", "latigo"] if d > 7.5 else ["latigo", "pitulin", "latigo"]
		return gl[randi() % gl.size()]
	var l = ["embestida", "embestida", "tajo"] if d > 7.5 else ["tajo", "barrido", "tajo", "barrido"]
	if ph > 1 and d < 7: l += ["repique", "repique"]
	return l[randi() % l.size()]

func attack(n, wm = 1.0):
	an = n; st = "wind"; var attacks = Cfg.GA if galileo else Cfg.A
	w = attacks[n].w * wm * (0.85 if ph > 1 else 1.0); t = w; hit = false; g.sfx("wind", -4.0)

func impact(a):
	g.shake = .35; g.sfx("boom")
	var off = Vector3.ZERO if a.k == "ring" else Vector3(sin(face), 0, cos(face)) * 2.6
	g.burst(position + off + Vector3(0, .3, 0), Color(.7, .65, .55), 14)

func take_hit(base, ppos):
	if st == "dead": return
	if st == "trans":
		g.burst(position + Vector3(0, 1.8, 0), Color(1, 1, 1), 6); return
	var dm = base * (1.0 + .1 * g.seed_bonus)
	if st == "rec": dm *= Cfg.B.punish
	var back = abs(angle_difference(face, atan2(ppos.x - position.x, ppos.z - position.z))) > 2.2
	if back:
		dm *= Cfg.B.back; g.say("¡Por la espalda!")
	hp -= dm; flash = .1; g.hs = .06; g.shake = .25; recoil = .7 if st == "rec" else .45; g.sfx("hit_back" if back else "hit")
	var col = Color(.5, .82, 1) if back else (Color(1, .85, .3) if st == "rec" else Color.WHITE)
	g.burst(position + Vector3(0, 1.8, 0), col, 16); g.number(position + Vector3(0, 3.8, 0), dm, col)
	if hp <= 0:
		hp = 0; st = "dead"; t = 2.6; an = ""; g.say("«…Cuídalo bien.»"); g.sfx("death")
	elif ph == 1 and hp <= Cfg.B.hp * Cfg.B.p2:
		ph = 2; st = "trans"; t = 2.4; an = ""; g.shake = .8
		robe.albedo_color = Color(.35, .17, .1); robe.emission_enabled = true; robe.emission = Color(.25, .06, .02)
		g.say("«¡Si no es mío, no será de nadie!»"); g.sfx("bell")

func step(dt):
	var v = g.player.position - position; v.y = 0; var d = v.length(); var want = atan2(v.x, v.z)
	flash = max(0.0, flash - dt); t -= dt
	match st:
		"idle":
			face = turn(face, want, 1.5 * dt)
			if d > 3.8:
				move(Cfg.B.spd * (1.25 if ph > 1 else 1.0) * dt); step_t -= dt
				if step_t <= 0:
					step_t = .55; g.shake = max(g.shake, .08); g.sfx("step", -6.0)
			if t <= 0 and (d < 8.5 or t < -1.0): attack(pick(d))
		"wind":
			var a = (Cfg.GA if galileo else Cfg.A)[an]
			if w - t < w * .35 and a.k != "ring": face = turn(face, want, 2.2 * dt)
			if t <= 0:
				st = "act"; t = a.a; impact(a)
		"act":
			var a = (Cfg.GA if galileo else Cfg.A)[an]
			if a.k == "dash": move(a.v * dt)
			if not hit:
				var da = abs(angle_difference(face, want)); var h = false
				if a.k == "ring": h = d < a.R
				elif a.k == "dash": h = d < a.R and da < .9
				else: h = d < a.R and da < deg_to_rad(a.g)
				if h and g.player.hurt(a.d): hit = true
			if t <= 0:
				if not galileo and an == "tajo" and ph > 1 and not cb and randf() < .45:
					cb = true; attack("barrido", .7)
				else:
					cb = false; st = "rec"; t = a.r; slide = a.v * .4 if a.k == "dash" else 0.0
		"rec":
			move(slide * dt); slide = move_toward(slide, 0.0, 12.0 * dt)
			if t <= 0:
				st = "idle"; t = (.4 + randf() * .5) * (0.7 if ph > 1 else 1.0)
		"trans":
			if t <= 0:
				st = "idle"; t = .8

func animate(dt):
	rotation.y = face
	var tx = -.2; var ty = 0.0
	if an != "" and (st == "wind" or st == "act" or st == "rec"):
		var wd = st == "wind"
		match an:
			"tajo", "latigo": tx = -2.3 if wd else .9
			"barrido":
				tx = 0.0; ty = 1.7 if wd else -1.7
			"embestida": tx = -.5 if wd else 0.0
			"pitulin": tx = -1.6 if wd else .6
			_: tx = -1.6 if wd else .6
	if pose_x != null: tx = pose_x
	var rt = min(dt * (30.0 if st == "act" else 5.0), 1.0)
	arm.rotation.x = lerpf(arm.rotation.x, tx, rt); arm.rotation.y = lerpf(arm.rotation.y, ty, rt)
	var active_body = galileo_body if galileo else body
	var active_arm = galileo_arm if galileo else arm
	var active_club = galileo_club if galileo else club
	active_body.position.y = lerpf(active_body.position.y, -1.2 if st == "dead" else 0.0, min(dt * 3.0, 1.0))
	recoil = move_toward(recoil, 0.0, dt * 3.0); active_body.position.z = -recoil; active_body.rotation.x = -recoil * .25
	active_body.rotation.z = lerpf(active_body.rotation.z, .9 if st == "dead" else sin(Time.get_ticks_msec() * .004) * .025, min(dt * 2.0, 1.0))
	active_arm.rotation.x = lerpf(active_arm.rotation.x, tx, rt)
	active_arm.rotation.y = lerpf(active_arm.rotation.y, ty, rt)
	active_club.emission_enabled = true
	active_club.emission = Color.WHITE if flash > 0 else (Color(.7 * (1.0 - t / w), 0, 0) if st == "wind" else Color.BLACK)
	for n in tele:
		var on = an == n and (st == "wind" or st == "act")
		tele[n].visible = on
		if on:
			var m = tele[n].material_override; var c = m.albedo_color
			c.a = .7 if st == "act" else .12 + .4 * (1.0 - t / w); m.albedo_color = c
