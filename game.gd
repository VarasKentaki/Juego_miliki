extends Node3D
# Núcleo: mundo, cámara, interfaz, estados (historia / juego / pausa / derrota / victoria).
const CONTROLS = "WASD mover · Ratón o ← → cámara · Clic izq. ataque rápido · Clic der. ataque pesado\nEspacio esquivar · Mayús correr · Q fijar objetivo · F curarse · 1 2 3 arma · R onda de pepino · G calidad · Esc pausa"
const STORY = [
"Ceuta ya no sonríe. Desde que se apagó el último faro, las gaviotas callan y el puerto huele a sal vieja. Nadie recuerda quién rio por última vez.",
"Miliki, el más terco de sus vecinos, sabe dónde buscar la alegría: en la huerta de Jimmy, donde crece el Pepino de Galileo, un artefacto legendario cargado de nutrientes capaces de devolver la felicidad a toda la ciudad.",
"Pero el pepino tiene guardián. Fuvu, el antiguo hortelano de Jimmy, lo vigila día y noche, convencido de que si alguien se lo come, Jimmy se quedará sin nada por lo que sonreír. Para comerlo, Miliki tendrá que vencerlo."]
var mode = "story"; var yaw = PI; var shake = 0.0; var hs = 0.0; var deaths = 0; var seed_bonus = 0; var story_i = 0; var clock = 0.0
var player: Player; var boss: Boss; var cam: Camera3D; var torches = []; var snd = {}; var music: AudioStreamPlayer
var sun; var env; var cine: Cine; var quality = 2; var dimmed = false; var intro_done = false
var logo: TextureRect; var cap_l: Label; var bars_t: ColorRect; var bars_b: ColorRect; var skip_l: Label; var sp_bar
var ui: CanvasLayer; var hp_bar; var st_bar; var boss_bar; var info: Label; var sub: Label; var bname: Label
var ov: ColorRect; var ov_label: Label; var ov_btn: Button; var on_btn: Callable

func _ready():
	randomize()
	var cf = ConfigFile.new()
	if cf.load("user://save.cfg") == OK: seed_bonus = cf.get_value("g", "seed", 0); quality = cf.get_value("g", "q", 2)
	_world(); _ui(); _audio(); _decor(); apply_quality()
	player = Player.new(); player.g = self; add_child(player)
	boss = Boss.new(); boss.g = self; add_child(boss)
	cine = Cine.new(); cine.g = self; add_child(cine)
	cam = Camera3D.new(); add_child(cam); cam.current = true
	reset(); next_story()

func _world():
	env = Environment.new(); var sk = Sky.new(); var sm = ProceduralSkyMaterial.new(); sm.sky_top_color = Color(.02, .04, .1); sm.sky_horizon_color = Color(.2, .28, .42); sm.ground_horizon_color = Color(.2, .28, .42); sm.ground_bottom_color = Color(.05, .07, .12); sk.sky_material = sm; env.sky = sk; env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(.4, .45, .62); env.ambient_light_energy = .7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.glow_enabled = true; env.glow_intensity = .9; env.ssao_enabled = true
	env.volumetric_fog_enabled = true; env.volumetric_fog_density = .025; env.volumetric_fog_albedo = Color(.35, .42, .6)
	var we = WorldEnvironment.new(); we.environment = env; add_child(we)
	sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, -30, 0); sun.light_color = Color(.65, .75, 1)
	sun.light_energy = 1.2; sun.shadow_enabled = true; add_child(sun)
	var nt = NoiseTexture2D.new(); nt.noise = FastNoiseLite.new(); nt.noise.frequency = .05; nt.seamless = true; nt.width = 512; nt.height = 512
	var gm = Models.mat(Color(.6, .6, .68)); gm.albedo_texture = nt; gm.uv1_scale = Vector3(6, 6, 6); gm.roughness = .9
	var gr = MeshInstance3D.new(); gr.mesh = Models.cyl(14, 14, .2); gr.material_override = gm; gr.position.y = -.1; add_child(gr)
	var wt = MeshInstance3D.new(); var pm = PlaneMesh.new(); pm.size = Vector2(120, 120); wt.mesh = pm
	var wm = Models.flat(Color(.1, .18, .28, .85)); wt.material_override = wm; wt.position.y = -.5; add_child(wt)
	for i in 12:
		var a = i / 12.0 * TAU
		var p = Models.part(self, Models.cyl(.7, .95, 9.0), Color(.34, .33, .4), Vector3(sin(a) * 11.5, 4.5, cos(a) * 11.5)); p.scale.y = .7 + randf() * .5
	for i in 4:
		var a = i * PI / 2 + PI / 4; var pos = Vector3(sin(a) * 9.8, 0, cos(a) * 9.8)
		Models.part(self, Models.cyl(.2, .13, .9), Color(.16, .14, .12), pos + Vector3(0, .45, 0))
		Models.part(self, Models.sph(.22), Color(1, .6, .2), pos + Vector3(0, 1.2, 0), Color(1, .45, .1))
		var l = OmniLight3D.new(); l.light_color = Color(1, .6, .3); l.omni_range = 14; l.position = pos + Vector3(0, 1.6, 0); add_child(l); torches.append(l)

func _audio():
	for n in ["swing_l", "swing_h", "hit", "hit_back", "hurt", "dodge", "heal", "wind", "boom", "bell", "death", "win", "step", "discover", "special"]:
		var p = "res://audio/" + n + ".wav"
		if ResourceLoader.exists(p): snd[n] = load(p)
	if ResourceLoader.exists("res://audio/music.wav"):
		var s = load("res://audio/music.wav"); s.loop_mode = AudioStreamWAV.LOOP_FORWARD; s.loop_end = int(s.data.size() / 2)
		music = AudioStreamPlayer.new(); music.stream = s; music.volume_db = -12.0; add_child(music); music.play()

func sfx(n, db = 0.0):
	if not snd.has(n): return
	var p = AudioStreamPlayer.new(); p.stream = snd[n]; p.volume_db = db; p.pitch_scale = randf_range(.95, 1.05); add_child(p); p.play(); p.finished.connect(p.queue_free)

func cap(t, s = ""):
	cap_l.text = (t + "\n" + s) if t != "" else ""

func dim(on):
	dimmed = on
	var tw = create_tween(); tw.set_parallel(true)
	tw.tween_property(sun, "light_energy", .12 if on else 1.2, .8); tw.tween_property(env, "ambient_light_energy", .15 if on else .7, .8)
	for l in torches: tw.tween_property(l, "light_energy", .2 if on else 1.4, .8)

func wave(p):
	var m = MeshInstance3D.new(); m.mesh = Models.sector(1.0, .7); m.material_override = Models.flat(Color(.5, 1, .4, .8))
	m.position = p.position + Vector3(0, .15, 0); m.rotation.y = p.face; m.scale = Vector3.ONE * .5; add_child(m)
	var tw = create_tween(); tw.set_parallel(true); tw.tween_property(m, "scale", Vector3.ONE * 13.0, .55); tw.tween_property(m.material_override, "albedo_color:a", 0.0, .55); tw.chain().tween_callback(m.queue_free)
	burst(p.position + Vector3(0, 1.2, 0) + Vector3(sin(p.face), 0, cos(p.face)) * 2.0, Color(.5, 1, .4), 30); shake = .5

func apply_quality():
	sun.shadow_enabled = quality > 0; env.ssao_enabled = quality > 1; env.volumetric_fog_enabled = quality > 1; env.glow_enabled = quality > 0
	get_viewport().msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][quality]

func cycle_quality():
	quality = (quality + 1) % 3; apply_quality(); save_cfg(); say(["Calidad baja", "Calidad media", "Calidad alta"][quality])

func save_cfg():
	var cf = ConfigFile.new(); cf.set_value("g", "seed", seed_bonus); cf.set_value("g", "q", quality); cf.save("user://save.cfg")

func _decor():
	var moon = Models.part(self, Models.sph(3.0), Color(.93, .95, 1), Vector3(-32, 26, -38), Color(.8, .9, 1)); moon.material_override.emission_energy_multiplier = 2.5
	var cols = [Color(.25, .45, .9), Color(.9, .65, .2), Color(.8, .2, .2), Color(.2, .7, .45)]
	for i in 6:
		var a = (i + .5) / 6.0 * TAU; var pos = Vector3(sin(a) * 15.5, 6, cos(a) * 15.5)
		var m = MeshInstance3D.new(); var q = QuadMesh.new(); q.size = Vector2(3.2, 8); m.mesh = q
		var wm = Models.mat(cols[i % 4], cols[i % 4]); wm.emission_energy_multiplier = 1.6; m.material_override = wm; m.position = pos; add_child(m); m.look_at(Vector3(pos.x * 2, 6, pos.z * 2))
		var l = OmniLight3D.new(); l.light_color = cols[i % 4]; l.light_energy = .8; l.omni_range = 9.0; l.position = Vector3(pos.x * .8, 5, pos.z * .8); add_child(l)
	var d = CPUParticles3D.new(); d.amount = 160; d.lifetime = 9.0; d.preprocess = 9.0; d.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX; d.emission_box_extents = Vector3(12, 4, 12); d.position.y = 4
	d.gravity = Vector3(0, .05, 0); d.initial_velocity_max = .2; d.mesh = Models.sph(.025); d.material_override = Models.mat(Color(.9, .9, .8), Color(.9, .9, .8)); add_child(d)
	var lf = CPUParticles3D.new(); lf.amount = 40; lf.lifetime = 10.0; lf.preprocess = 10.0; lf.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX; lf.emission_box_extents = Vector3(12, .5, 12); lf.position.y = 9
	lf.gravity = Vector3(.3, -.7, 0); lf.initial_velocity_max = .3; lf.angular_velocity_max = 180.0; var qm = QuadMesh.new(); qm.size = Vector2(.14, .1); lf.mesh = qm
	var lm = Models.mat(Color(.4, .5, .2)); lm.cull_mode = BaseMaterial3D.CULL_DISABLED; lf.material_override = lm; add_child(lf)

func bar(col, pos, size):
	var b = ProgressBar.new(); b.max_value = 1.0; b.value = 1.0; b.show_percentage = false; b.position = pos; b.size = size; b.custom_minimum_size = size
	var f = StyleBoxFlat.new(); f.bg_color = col; b.add_theme_stylebox_override("fill", f)
	var bg = StyleBoxFlat.new(); bg.bg_color = Color(0, 0, 0, .6); bg.border_color = Color(.75, .58, .3); bg.set_border_width_all(1); b.add_theme_stylebox_override("background", bg)
	ui.add_child(b); return b

func lab(size, pos):
	var l = Label.new(); l.add_theme_font_size_override("font_size", size); l.position = pos; l.add_theme_color_override("font_outline_color", Color.BLACK); l.add_theme_constant_override("outline_size", 6); ui.add_child(l); return l

func _ui():
	ui = CanvasLayer.new(); add_child(ui)
	hp_bar = bar(Color(.65, .15, .15), Vector2(20, 20), Vector2(320, 14)); st_bar = bar(Color(.45, .65, .3), Vector2(20, 40), Vector2(240, 9))
	boss_bar = bar(Color(.56, .14, .14), Vector2(0, 0), Vector2(620, 12))
	sp_bar = bar(Color(.9, .75, .25), Vector2(20, 52), Vector2(200, 6)); info = lab(16, Vector2(20, 62))
	cap_l = lab(40, Vector2(0, 0)); skip_l = lab(14, Vector2(0, 0)); skip_l.text = "Espacio / clic: saltar"
	bars_t = ColorRect.new(); bars_t.color = Color.BLACK; ui.add_child(bars_t); bars_b = ColorRect.new(); bars_b.color = Color.BLACK; ui.add_child(bars_b)
	sub = lab(24, Vector2(0, 0)); bname = lab(22, Vector2(0, 0)); bname.text = "Fuvu, Guardián del Pepino"
	ov = ColorRect.new(); ov.color = Color(.03, .03, .05, .9); ov.set_anchors_preset(Control.PRESET_FULL_RECT); ui.add_child(ov)
	var cc = CenterContainer.new(); cc.set_anchors_preset(Control.PRESET_FULL_RECT); ov.add_child(cc)
	var vb = VBoxContainer.new(); vb.custom_minimum_size.x = 620; cc.add_child(vb)
	logo = TextureRect.new(); logo.custom_minimum_size = Vector2(420, 170); logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists("res://logo.svg"): logo.texture = load("res://logo.svg")
	vb.add_child(logo)
	ov_label = Label.new(); ov_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; ov_label.add_theme_font_size_override("font_size", 22); vb.add_child(ov_label)
	ov_btn = Button.new(); ov_btn.focus_mode = Control.FOCUS_NONE; ov_btn.add_theme_font_size_override("font_size", 22); vb.add_child(ov_btn)
	var sb = StyleBoxFlat.new(); sb.bg_color = Color(.08, .07, .1); sb.border_color = Color(.75, .58, .3); sb.set_border_width_all(2); sb.set_content_margin_all(10); ov_btn.add_theme_stylebox_override("normal", sb)
	var sh = sb.duplicate(); sh.bg_color = Color(.75, .58, .3); ov_btn.add_theme_stylebox_override("hover", sh); ov_btn.add_theme_color_override("font_hover_color", Color(.05, .05, .07))
	ov_btn.pressed.connect(func(): on_btn.call())

func overlay(txt, btn, cb: Callable):
	ov_label.text = txt; ov_btn.text = btn; on_btn = cb; ov.visible = true; Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	logo.visible = false; ov.modulate.a = 0.0; create_tween().tween_property(ov, "modulate:a", 1.0, .35)

func start_play():
	ov.visible = false; mode = "play"; Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func reset():
	player.reset(); boss.reset(); yaw = PI; shake = 0.0; hs = 0.0

func fresh():
	reset()
	if not intro_done:
		intro_done = true; ov.visible = false; await cine.intro()
	start_play(); say("«¡El pepino es mío, Miliki!»")

func next_story():
	if story_i >= STORY.size(): fresh(); return
	var last = story_i == STORY.size() - 1
	overlay(STORY[story_i] + ("\n\n" + CONTROLS if last else ""), "Enfrentar a Fuvu" if last else "Continuar", next_story)
	logo.visible = story_i == 0
	story_i += 1

func die():
	mode = "cine"; deaths += 1
	await cine.defeat()
	mode = "dead"
	var L = ["«El pepino es mío.»", "«Ceuta no necesita sonreír.»", "«Jimmy me lo confió a mí.»"]
	overlay("HAS CAÍDO\n\n" + L[deaths % 3] + "\n\nIntento " + str(deaths) + ". Rodea a Fuvu: no gira tan rápido como tú, y tras cada golpe queda expuesto.", "Volver a intentarlo", fresh)

func win():
	mode = "cine"
	await cine.victory()
	mode = "win"; seed_bonus = 1; save_cfg()
	overlay("CEUTA SONRÍE\n\nFuvu fue el hortelano de Jimmy. Cuando la alegría abandonó Ceuta, el último pepino fue lo único que siguió creciendo, y él lo guardó noche y día, sin entender que un pepino guardado no alimenta a nadie.\n\nMiliki lo muerde. Un sabor fresco recorre la ciudad: las gaviotas vuelven a cantar, el Estrecho brilla y en el puerto alguien se ríe por primera vez en años.\n\nRecompensa: Pepino de Galileo. +10 % de daño y la Onda de Pepino (tecla R) cuando la barra dorada esté llena.", "Volver a luchar", fresh)

func say(t):
	sub.text = t; sub.modulate.a = 1.0
	var tw = create_tween(); tw.tween_interval(3.0); tw.tween_property(sub, "modulate:a", 0.0, .6)

func burst(pos, col, n = 16):
	var p = CPUParticles3D.new(); p.one_shot = true; p.emitting = true; p.amount = n; p.lifetime = .6; p.explosiveness = 1.0
	p.direction = Vector3.UP; p.spread = 180.0; p.initial_velocity_min = 3.0; p.initial_velocity_max = 7.0; p.gravity = Vector3(0, -14, 0)
	p.mesh = Models.sph(.05); p.material_override = Models.mat(col, col); p.position = pos; add_child(p)
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)

func number(pos, v, col):
	var l = Label3D.new(); l.text = str(int(round(v))); l.font_size = 72; l.modulate = col; l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.no_depth_test = true; l.position = pos; add_child(l)
	var tw = create_tween(); tw.set_parallel(true); tw.tween_property(l, "position:y", pos.y + 1.5, .9); tw.tween_property(l, "modulate:a", 0.0, .9); tw.chain().tween_callback(l.queue_free)

func _unhandled_input(e):
	if mode == "cine":
		if (e is InputEventKey and e.pressed and e.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_ESCAPE]) or (e is InputEventMouseButton and e.pressed): cine.skip = true
		return
	if e is InputEventKey and e.pressed and not e.echo:
		if e.physical_keycode == KEY_ESCAPE and mode == "play":
			mode = "pause"; overlay("PAUSA\n\n" + CONTROLS, "Continuar", start_play)
		elif mode == "play":
			match e.physical_keycode:
				KEY_SPACE: player.try_act("D")
				KEY_F: player.try_act("F")
				KEY_Q: player.lock = not player.lock
				KEY_R: player.try_act("S")
				KEY_G: cycle_quality()
				KEY_1: player.switch("espada")
				KEY_2: player.switch("hacha")
				KEY_3: player.switch("podadera")
	elif e is InputEventMouseButton and e.pressed and mode == "play":
		if e.button_index == MOUSE_BUTTON_LEFT: player.try_act("L")
		elif e.button_index == MOUSE_BUTTON_RIGHT: player.try_act("H")
	elif e is InputEventMouseMotion and mode == "play" and not player.lock and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= e.relative.x * .003

func _process(dt):
	clock += dt
	if mode == "play":
		if hs > 0: hs -= dt
		else:
			player.step(dt); boss.step(dt)
			if player.hp <= 0: die()
			elif boss.st == "dead" and boss.t <= 0: win()
	player.animate(dt); boss.animate(dt)
	if not dimmed:
		for i in torches.size(): torches[i].light_energy = 1.4 + sin(clock * 12.0 + i) * .4
	if mode != "cine": _cam(dt)
	_hud()

func _cam(dt):
	var p = player.position; var b = boss.position
	if player.act == "S":
		var f = Vector3(sin(player.face), 0, cos(player.face))
		cam.position = p + f * 2.8 + Vector3(f.z, 0, -f.x) * 1.4 + Vector3(0, 1.7, 0); cam.look_at(p + Vector3(0, 1.5, 0) + f * 1.5); return
	if mode == "story": yaw += dt * .15
	elif player.lock: yaw += angle_difference(yaw, atan2(b.x - p.x, b.z - p.z)) * min(1.0, dt * 5.0)
	if Input.is_physical_key_pressed(KEY_LEFT): yaw += 1.8 * dt
	if Input.is_physical_key_pressed(KEY_RIGHT): yaw -= 1.8 * dt
	var c = p - Vector3(sin(yaw), 0, cos(yaw)) * 6.5; c.y = 3.6
	var h = Vector2(c.x, c.z).length()
	if h > 11.0:
		c.x *= 11.0 / h; c.z *= 11.0 / h
	shake *= .9; c += Vector3(randf() - .5, randf() - .5, randf() - .5) * shake
	cam.position = c
	var k = .3 if player.lock else 0.0
	cam.look_at(Vector3(p.x + (b.x - p.x) * k, 1.6, p.z + (b.z - p.z) * k))

func _hud():
	var vp = get_viewport().get_visible_rect().size; var show = mode != "story" and mode != "cine"
	var cn = mode == "cine"; bars_t.visible = cn; bars_b.visible = cn; skip_l.visible = cn
	bars_t.size = Vector2(vp.x, vp.y * .11); bars_b.size = Vector2(vp.x, vp.y * .11); bars_b.position = Vector2(0, vp.y * .89)
	cap_l.position = Vector2(vp.x * .1, vp.y * .7); skip_l.position = Vector2(vp.x - 230, vp.y - 36)
	sp_bar.visible = show and seed_bonus > 0; sp_bar.value = player.meter / 100.0
	hp_bar.visible = show; st_bar.visible = show; boss_bar.visible = show; bname.visible = show; info.visible = show
	hp_bar.value = player.hp / Cfg.P.hp; st_bar.value = player.st / Cfg.P.st; boss_bar.value = boss.hp / Cfg.B.hp
	boss_bar.position = Vector2((vp.x - 620) / 2, vp.y - 44); bname.position = Vector2((vp.x - 300) / 2, vp.y - 80); sub.position = Vector2(vp.x / 2 - 200, vp.y * .16)
	info.text = player.wd().name + "   Frascos " + "◆".repeat(player.fl) + "◇".repeat(Cfg.P.fl - player.fl) + ("   ◉ fijado" if player.lock else "") + ("   ✦ Pepino de Galileo" if seed_bonus > 0 else "")
