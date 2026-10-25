class_name Cine extends Node
# Cinemáticas con cámara dirigida: inicio de combate, victoria, descubrimiento del Pepino de Galileo y derrota.
# Todas se pueden saltar (Espacio, Intro, Esc o clic): "skip" corta los planos y cada secuencia limpia lo que creó.
var g; var skip = false

func fr(n): return Vector3(sin(n.face), 0, cos(n.face))
func hd(n, h): return n.position + Vector3(0, h, 0)

func tick():
	await get_tree().process_frame
	return g.get_process_delta_time()

func wait(d):
	var t = 0.0
	while t < d and not skip: t += await tick()

func shot(ap, al, bp, bl, d):
	var t = 0.0
	while t < d and not skip:
		var k = smoothstep(0.0, 1.0, t / d)
		g.cam.position = ap.lerp(bp, k); g.cam.look_at(al.lerp(bl, k))
		t += await tick()

func intro():
	g.mode = "cine"; skip = false
	var p = g.player; var b = g.boss; var f = fr(p); var fb = fr(b)
	g.sfx("wind", -6.0)
	await shot(Vector3(0, 9, 15), Vector3(0, 1.5, 0), Vector3(-10, 5, 8), Vector3(0, 1.5, -1), 2.4)
	g.cap("MILIKI", "el más terco de Ceuta"); g.sfx("swing_h", -6.0)
	await shot(p.position + f * 2.4 + Vector3(.6, 1.7, 0), hd(p, 1.6), p.position + f * 1.6 + Vector3(.3, 1.65, 0), hd(p, 1.65), 1.7)
	g.cap("FUVU", "guardián del pepino"); g.sfx("boom", -4.0)
	await shot(b.position + fb * 5.0 + Vector3(1.2, 3.0, 0), hd(b, 3.2), b.position + fb * 3.3 + Vector3(.6, 3.3, 0), hd(b, 3.3), 2.0)
	g.cap(""); g.say("«¡El pepino es mío, Miliki!»")
	await shot(Vector3(7, 2.4, 1.5), Vector3(0, 1.8, 1.5), Vector3(6, 2.0, 1.5), Vector3(0, 1.8, 1.5), 1.3)
	g.cap(""); g.yaw = PI

func victory():
	g.mode = "cine"; skip = false
	var p = g.player; var b = g.boss; var f = fr(p)
	p.pose = "win"; g.sfx("win"); g.burst(p.position + Vector3(0, 1.8, 0), Color(1, .85, .3), 40); g.say("«…Cuídalo bien.»")
	await shot(p.position + f * 3.0 + Vector3(1.2, .4, 0), hd(p, 1.4), p.position + f * 2.4 + Vector3(1.6, 1.9, 0), hd(p, 1.7), 2.6)
	await shot(b.position + fr(b) * 4.0 + Vector3(2, 1.2, 0), hd(b, .6), b.position + fr(b) * 3.2 + Vector3(1.5, 1.8, 0), hd(b, .8), 1.8)
	p.pose = ""
	await pepino()
	g.cap("")

func galileo_intro():
	g.mode = "cine"; skip = false
	var b = g.boss
	g.dim(true); g.sfx("bell")
	g.cap("GALILEO", "el dueño de la huerta")
	await shot(b.position + Vector3(6, 3.0, 6), hd(b, 2.0), b.position + Vector3(4, 2.2, 4), hd(b, 2.8), 2.2)
	g.cap("GALILEO", "«¡No toques mi pitulín! Así llamo al pepino de mi huerto.»")
	await wait(2.6)
	g.dim(false); g.cap(""); g.say("Fuvu solo era el guardián. La huerta acaba de despertar.")

func pepino():
	var p = g.player; var b = g.boss
	var c = (p.position + b.position) * .5; c.y = 0.0
	p.face = atan2(c.x - p.position.x, c.z - p.position.z)
	g.sfx("discover"); g.dim(true)
	var pep = Models.pepino(true); pep.position = c + Vector3(0, .3, 0); pep.scale = Vector3.ONE * .1; g.add_child(pep)
	var sp = SpotLight3D.new(); sp.position = c + Vector3(0, 7, 0); sp.rotation_degrees = Vector3(-90, 0, 0); sp.spot_range = 12.0; sp.spot_angle = 24.0; sp.light_energy = 8.0; sp.light_color = Color(1, .95, .7); g.add_child(sp)
	var tw = create_tween(); tw.set_parallel(true)
	tw.tween_property(pep, "position:y", 1.9, 2.2).set_trans(Tween.TRANS_SINE); tw.tween_property(pep, "scale", Vector3.ONE * 1.2, 2.2)
	await shot(c + Vector3(3.2, .5, 3.2), c + Vector3(0, .6, 0), c + Vector3(2.6, 1.0, 2.6), c + Vector3(0, 1.4, 0), 1.6)
	var t = 0.0
	while t < 3.4 and not skip:
		var a = t * .8 + .8; pep.rotation.y += .03
		g.cam.position = c + Vector3(cos(a) * 3.2, 1.5 + sin(t) * .3, sin(a) * 3.2); g.cam.look_at(pep.position)
		t += await tick()
	g.cap("PEPINO DE GALILEO", "ARTEFACTO LEGENDARIO"); g.burst(pep.position, Color(1, .9, .4), 36)
	g.say("Rareza: 1 de 1. Lo cultivó Jimmy y lo envidia toda la huerta.\nPoderes: refresca, ilumina y, lanzado con ganas, abolla.")
	await wait(3.6)
	tw.kill()
	create_tween().tween_property(pep, "global_position", p.position + Vector3(0, 1.5, 0), .5)
	await wait(.5)
	pep.queue_free(); sp.queue_free(); g.dim(false); g.sfx("heal"); g.burst(p.position + Vector3(0, 1.6, 0), Color(.6, 1, .4), 30)

func defeat():
	g.mode = "cine"; skip = false
	var p = g.player; var b = g.boss
	p.pose = "lose"; g.sfx("death", -4.0); b.pose_x = -2.3
	var L = ["«El pepino es mío.»", "«Ceuta no necesita sonreír.»", "«Jimmy me lo confió a mí.»"]
	g.say(L[g.deaths % 3])
	await shot(p.position + Vector3(2.5, 1.6, 3.0), hd(p, .5), p.position + Vector3(4.5, 3.8, 4.5), hd(p, .3), 2.2)
	await shot(b.position + fr(b) * 4.5 + Vector3(1.5, 1.4, 0), hd(b, 3.0), b.position + fr(b) * 4.0 + Vector3(.8, 2.2, 0), hd(b, 3.4), 1.5)
	g.cap("")
