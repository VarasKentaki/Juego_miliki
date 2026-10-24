class_name Player extends Node3D
var g
var hp = 100.0; var st = 100.0; var st_t = 0.0; var fl = 3
var face = PI; var act = ""; var at = 0.0; var hit = false; var dir = Vector3.ZERO; var lock = true
var sword: Node3D; var body: Node3D; var slash: MeshInstance3D
var weapon = "espada"; var wnode: Node3D; var trail; var cape: Node3D; var tail: Node3D
var vel = Vector3.ZERO; var kb = Vector3.ZERO; var cape_a = .1; var cape_v = 0.0

func _ready():
	var m = Models.miliki(); body = m.root; sword = m.sword; cape = m.cape; tail = m.tail; add_child(body)
	slash = MeshInstance3D.new(); slash.mesh = Models.sector(1.0, 1.1); slash.material_override = Models.flat(Color(1, .95, .75, .7))
	slash.position.y = .9; slash.visible = false; add_child(slash)
	set_weapon("espada")

func wd(): return Cfg.W[weapon]

func set_weapon(n):
	weapon = n
	if wnode: wnode.queue_free()
	wnode = Models.weapon(n); sword.add_child(wnode); trail = wnode.get_node("Trail")
	slash.mesh = Models.sector(1.0, wd().arc)

func switch(n):
	if act == "" and n != weapon:
		set_weapon(n); g.say(wd().name)

func reset():
	vel = Vector3.ZERO; kb = Vector3.ZERO
	hp = Cfg.P.hp; st = Cfg.P.st; fl = Cfg.P.fl; act = ""; position = Vector3(0, 0, 6); face = PI; lock = true

func use(c) -> bool:
	if st <= 0: return false
	st = max(0.0, st - c); st_t = Cfg.P.dly; return true

func inp() -> Vector3:
	var f = Vector3(sin(g.yaw), 0, cos(g.yaw)); var r = Vector3(-cos(g.yaw), 0, sin(g.yaw))
	var fw = int(Input.is_physical_key_pressed(KEY_W)) - int(Input.is_physical_key_pressed(KEY_S))
	var rt = int(Input.is_physical_key_pressed(KEY_D)) - int(Input.is_physical_key_pressed(KEY_A))
	return (f * fw + r * rt).normalized()

func to_boss() -> float:
	return atan2(g.boss.position.x - position.x, g.boss.position.z - position.z)

func try_act(k):
	if act != "": return
	if k == "D":
		if not use(Cfg.P.dcost): return
		var v = inp(); dir = v if v != Vector3.ZERO else -Vector3(sin(face), 0, cos(face))
	elif k == "F":
		if fl < 1 or hp >= Cfg.P.hp: return
	else:
		if not use(wd()[k].c): return
		if lock: face = to_boss()
		hit = false; vel = Vector3(sin(face), 0, cos(face)) * 3.5
	act = k; at = 0.0
	g.sfx({"D": "dodge", "L": "swing_l", "H": "swing_h"}.get(k, ""))

func invuln() -> bool:
	return act == "D" and at >= Cfg.P.i0 and at <= Cfg.P.i1

func hurt(dm) -> bool:
	if invuln(): return false
	hp = max(0.0, hp - dm); act = ""; g.shake = .5; g.hs = .07; g.sfx("hurt")
	var aw = position - g.boss.position; aw.y = 0; kb = aw.normalized() * 7.0; vel = Vector3.ZERO; cape_v += 6.0
	g.burst(position + Vector3(0, 1.2, 0), Color(.75, .1, .1), 14); return true

func strike(d):
	var b = g.boss.position; var dx = b.x - position.x; var dz = b.z - position.z
	if sqrt(dx * dx + dz * dz) - Cfg.B.rad > d.r or abs(angle_difference(face, atan2(dx, dz))) > wd().arc: return
	hit = true; g.boss.take_hit(d.d, position)

func step(dt):
	st_t -= dt
	position += kb * dt; kb = kb.move_toward(Vector3.ZERO, 30.0 * dt)
	if st_t <= 0: st = min(Cfg.P.st, st + Cfg.P.rec * dt)
	if act != "":
		at += dt
		if act == "D":
			position += dir * Cfg.P.dspd * dt * (1.0 - 0.5 * at / Cfg.P.dt)
			if at >= Cfg.P.dt:
				act = ""; vel = dir * 4.0
		elif act == "F":
			if at >= Cfg.P.ht:
				fl -= 1; hp = min(Cfg.P.hp, hp + Cfg.P.heal); act = ""; g.say("Un sorbo de té de menta."); g.sfx("heal")
		else:
			var d = wd()[act]; position += vel * dt; vel = vel.move_toward(Vector3.ZERO, 14.0 * dt)
			if not hit and at >= d.a and at <= d.b: strike(d)
			if at >= d.t: act = ""
	else:
		var v = inp(); var sp = Cfg.P.spd * wd().spd
		if Input.is_physical_key_pressed(KEY_SHIFT) and st > 0 and v != Vector3.ZERO:
			sp = Cfg.P.spr; st = max(0.0, st - 14.0 * dt); st_t = Cfg.P.dly
		vel = vel.move_toward(v * sp, (45.0 if v != Vector3.ZERO else 32.0) * dt); position += vel * dt
		if lock: face = to_boss()
		elif v != Vector3.ZERO: face = atan2(v.x, v.z)
	var h = Vector2(position.x, position.z).length()
	if h > Cfg.ARENA:
		position.x *= Cfg.ARENA / h; position.z *= Cfg.ARENA / h
	var b = g.boss.position; var dx = position.x - b.x; var dz = position.z - b.z; var d2 = sqrt(dx * dx + dz * dz); var m = Cfg.B.rad + .45
	if d2 < m and d2 > 0:
		position.x = b.x + dx / d2 * m; position.z = b.z + dz / d2 * m
	position.y = 0

func animate(dt):
	rotation.y = face; var rx = 0.0; slash.visible = false; trail.emitting = false
	if act == "L" or act == "H":
		var d = wd()[act]; var t = at
		if t < d.a: rx = lerpf(0.0, -2.2, t / d.a)
		elif t < d.b: rx = lerpf(-2.2, 1.0, (t - d.a) / (d.b - d.a))
		else: rx = lerpf(1.0, 0.0, clamp((t - d.b) / (d.t - d.b), 0.0, 1.0))
		var k = (t - d.a) / (d.b - d.a + .12)
		trail.emitting = t >= d.a - .05 and t <= d.b + .1
		if k >= 0.0 and k < 1.0:
			slash.visible = true; slash.scale = Vector3.ONE * d.r
			var cc = wd().col; slash.material_override.albedo_color = Color(cc[0], cc[1], cc[2], (.9 if act == "H" else .6) * (1.0 - k))
	elif act == "F": rx = -.8
	sword.rotation.x = rx
	body.scale.y = .6 if act == "D" else 1.0
	body.visible = not (invuln() and int(at * 40) % 2 == 1)
	var tg = .12 + clamp(vel.length() * .09, 0.0, .8) + sin(Time.get_ticks_msec() * .004) * .04
	cape_v += ((tg - cape_a) * 70.0 - cape_v * 7.0) * dt; cape_a += cape_v * dt
	cape.rotation.x = cape_a; tail.rotation.x = cape_a * 1.3 + sin(Time.get_ticks_msec() * .006) * .1
