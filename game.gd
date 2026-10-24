extends Node3D
# Núcleo: mundo, cámara, interfaz, estados (historia / juego / pausa / derrota / victoria).
const CONTROLS = "WASD mover · Ratón o ← → cámara · Clic izq. ataque rápido · Clic der. ataque pesado\nEspacio esquivar · Mayús correr · Q fijar objetivo · F curarse · 1 2 3 arma · Esc pausa"
const STORY = [
"Ceuta ya no sonríe. Desde que se apagó el último faro, las gaviotas callan y el puerto huele a sal vieja. Nadie recuerda quién rio por última vez.",
"Miliki, el más terco de sus vecinos, sabe dónde buscar la alegría: en la huerta de Jimmy, donde crece un pepino cargado de nutrientes capaces de devolver la felicidad a toda la ciudad.",
"Pero el pepino tiene guardián. Fuvu, el antiguo hortelano de Jimmy, lo vigila día y noche, convencido de que si alguien se lo come, Jimmy se quedará sin nada por lo que sonreír. Para comerlo, Miliki tendrá que vencerlo."]
var mode = "story"; var yaw = PI; var shake = 0.0; var hs = 0.0; var deaths = 0; var seed_bonus = 0; var story_i = 0; var clock = 0.0
var player: Player; var boss: Boss; var cam: Camera3D; var torches = []; var snd = {}; var music: AudioStreamPlayer
var ui: CanvasLayer; var hp_bar; var st_bar; var boss_bar; var info: Label; var sub: Label; var bname: Label
var ov: ColorRect; var ov_label: Label; var ov_btn: Button; var on_btn: Callable

func _ready():
	randomize()
	var cf = ConfigFile.new()
	if cf.load("user://save.cfg") == OK: seed_bonus = cf.get_value("g", "seed", 0)
	_world(); _ui(); _audio()
	player = Player.new(); player.g = self; add_child(player)
	boss = Boss.new(); boss.g = self; add_child(boss)
	cam = Camera3D.new(); add_child(cam); cam.current = true
	reset(); next_story()

func _world():
	var env = Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(.07, .1, .17)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(.4, .45, .62); env.ambient_light_energy = .7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.glow_enabled = true; env.glow_intensity = .9; env.ssao_enabled = true
	env.volumetric_fog_enabled = true; env.volumetric_fog_density = .025; env.volumetric_fog_albedo = Color(.35, .42, .6)
	var we = WorldEnvironment.new(); we.environment = env; add_child(we)
	var sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, -30, 0); sun.light_color = Color(.65, .75, 1)
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
	for n in ["swing_l", "swing_h", "hit", "hit_back", "hurt", "dodge", "heal", "wind", "boom", "bell", "death", "win", "step"]:
		var p = "res://audio/" + n + ".wav"
		if ResourceLoader.exists(p): snd[n] = load(p)
	if ResourceLoader.exists("res://audio/music.wav"):
		var s = load("res://audio/music.wav"); s.loop_mode = AudioStreamWAV.LOOP_FORWARD; s.loop_end = int(s.data.size() / 2)
		music = AudioStreamPlayer.new(); music.stream = s; music.volume_db = -12.0; add_child(music); music.play()

func sfx(n, db = 0.0):
	if not snd.has(n): return
	var p = AudioStreamPlayer.new(); p.stream = snd[n]; p.volume_db = db; p.pitch_scale = randf_range(.95, 1.05); add_child(p); p.play(); p.finished.connect(p.queue_free)

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
	info = lab(16, Vector2(20, 54)); sub = lab(24, Vector2(0, 0)); bname = lab(22, Vector2(0, 0)); bname.text = "Fuvu, Guardián del Pepino"
	ov = ColorRect.new(); ov.color = Color(.03, .03, .05, .9); ov.set_anchors_preset(Control.PRESET_FULL_RECT); ui.add_child(ov)
	var cc = CenterContainer.new(); cc.set_anchors_preset(Control.PRESET_FULL_RECT); ov.add_child(cc)
	var vb = VBoxContainer.new(); vb.custom_minimum_size.x = 620; cc.add_child(vb)
	ov_label = Label.new(); ov_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; ov_label.add_theme_font_size_override("font_size", 22); vb.add_child(ov_label)
	ov_btn = Button.new(); ov_btn.focus_mode = Control.FOCUS_NONE; ov_btn.add_theme_font_size_override("font_size", 22); vb.add_child(ov_btn)
	ov_btn.pressed.connect(func(): on_btn.call())

func overlay(txt, btn, cb: Callable):
	ov_label.text = txt; ov_btn.text = btn; on_btn = cb; ov.visible = true; Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func start_play():
	ov.visible = false; mode = "play"; Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func reset():
	player.reset(); boss.reset(); yaw = PI; shake = 0.0; hs = 0.0

func fresh():
	reset(); start_play(); say("«¡El pepino es mío, Miliki!»")

func next_story():
	if story_i >= STORY.size(): fresh(); return
	var last = story_i == STORY.size() - 1
	overlay("MILIKI Y EL PEPINO\n\n" + STORY[story_i] + ("\n\n" + CONTROLS if last else ""), "Enfrentar a Fuvu" if last else "Continuar", next_story)
	story_i += 1

func die():
	mode = "dead"; deaths += 1; sfx("death", -4.0)
	var L = ["«El pepino es mío.»", "«Ceuta no necesita sonreír.»", "«Jimmy me lo confió a mí.»"]
	overlay("HAS CAÍDO\n\n" + L[deaths % 3] + "\n\nIntento " + str(deaths) + ". Rodea a Fuvu: no gira tan rápido como tú, y tras cada golpe queda expuesto.", "Volver a intentarlo", fresh)

func win():
	mode = "win"; seed_bonus = 1; sfx("win")
	var cf = ConfigFile.new(); cf.set_value("g", "seed", 1); cf.save("user://save.cfg")
	overlay("CEUTA SONRÍE\n\nFuvu fue el hortelano de Jimmy. Cuando la alegría abandonó Ceuta, el último pepino fue lo único que siguió creciendo, y él lo guardó noche y día, sin entender que un pepino guardado no alimenta a nadie.\n\nMiliki lo muerde. Un sabor fresco recorre la ciudad: las gaviotas vuelven a cantar, el Estrecho brilla y en el puerto alguien se ríe por primera vez en años.\n\nRecompensa: Semilla de Jimmy (+10 % de daño).", "Volver a luchar", fresh)

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
	if e is InputEventKey and e.pressed and not e.echo:
		if e.physical_keycode == KEY_ESCAPE and mode == "play":
			mode = "pause"; overlay("PAUSA\n\n" + CONTROLS, "Continuar", start_play)
		elif mode == "play":
			match e.physical_keycode:
				KEY_SPACE: player.try_act("D")
				KEY_F: player.try_act("F")
				KEY_Q: player.lock = not player.lock
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
	for i in torches.size(): torches[i].light_energy = 1.4 + sin(clock * 12.0 + i) * .4
	_cam(dt); _hud()

func _cam(dt):
	var p = player.position; var b = boss.position
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
	var vp = get_viewport().get_visible_rect().size; var show = mode != "story"
	hp_bar.visible = show; st_bar.visible = show; boss_bar.visible = show; bname.visible = show; info.visible = show
	hp_bar.value = player.hp / Cfg.P.hp; st_bar.value = player.st / Cfg.P.st; boss_bar.value = boss.hp / Cfg.B.hp
	boss_bar.position = Vector2((vp.x - 620) / 2, vp.y - 44); bname.position = Vector2((vp.x - 300) / 2, vp.y - 80); sub.position = Vector2(vp.x / 2 - 200, vp.y * .16)
	info.text = player.wd().name + "   Frascos " + "◆".repeat(player.fl) + "◇".repeat(Cfg.P.fl - player.fl) + ("   ◉ fijado" if player.lock else "") + ("   ✦ Semilla de Jimmy" if seed_bonus > 0 else "")
