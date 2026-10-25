class_name Models
# Modelos procedurales (sustituibles por .glb de Blender sin tocar la lógica).
static func mat(c: Color, e: Color = Color.BLACK) -> StandardMaterial3D:
	var s = StandardMaterial3D.new(); s.albedo_color = c; s.roughness = 0.75; s.metallic = 0.1
	if e != Color.BLACK:
		s.emission_enabled = true; s.emission = e
	return s
static func flat(c: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
static func sph(r: float) -> SphereMesh:
	var m = SphereMesh.new(); m.radius = r; m.height = r * 2.0; return m
static func cyl(t: float, b: float, h: float) -> CylinderMesh:
	var m = CylinderMesh.new(); m.top_radius = t; m.bottom_radius = b; m.height = h; return m
static func cone(r: float, h: float) -> CylinderMesh:
	return cyl(0.0, r, h)
static func box(x: float, y: float, z: float) -> BoxMesh:
	var m = BoxMesh.new(); m.size = Vector3(x, y, z); return m
static func tor(i: float, o: float) -> TorusMesh:
	var m = TorusMesh.new(); m.inner_radius = i; m.outer_radius = o; return m
static func part(p: Node3D, mesh: Mesh, c: Color, pos: Vector3, e: Color = Color.BLACK) -> MeshInstance3D:
	var m = MeshInstance3D.new(); m.mesh = mesh; m.material_override = mat(c, e); m.position = pos; p.add_child(m); return m
static func sector(R: float, hg: float) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n = 24
	for i in n:
		var a0 = -hg + 2.0 * hg * i / n
		var a1 = -hg + 2.0 * hg * (i + 1) / n
		st.add_vertex(Vector3.ZERO); st.add_vertex(Vector3(sin(a1), 0, cos(a1)) * R); st.add_vertex(Vector3(sin(a0), 0, cos(a0)) * R)
	return st.commit()
static func face(p: Node3D, y: float, z: float, s: float, eye: Color, glow: bool) -> void:
	for k in [-1, 1]:
		part(p, sph(.06 * s), Color(.96, .96, .93), Vector3(.11 * s * k, y + .03 * s, z))
		part(p, sph(.034 * s), eye, Vector3(.11 * s * k, y + .03 * s, z + .045 * s), eye if glow else Color.BLACK)
		var b = part(p, box(.11 * s, .02 * s, .03 * s), Color(.1, .07, .06), Vector3(.11 * s * k, y + .1 * s, z + .02 * s))
		b.rotation.z = -.3 * k
	part(p, cone(.035 * s, .1 * s), Color(.75, .6, .47), Vector3(0, y - .03 * s, z + .05 * s)).rotation.x = PI / 2
	part(p, box(.12 * s, .02 * s, .03 * s), Color(.23, .08, .06), Vector3(0, y - .12 * s, z + .02 * s))
static func miliki() -> Dictionary:
	var r = Node3D.new(); var skin = Color(.88, .7, .56); var tun = Color(.42, .48, .6)
	var legs = []; var arms = []
	for k in [-1, 1]:
		var lg = Node3D.new(); lg.position = Vector3(.17 * k, .75, 0); r.add_child(lg); legs.append(lg)
		part(lg, cyl(.11, .1, .7), Color(.23, .2, .31), Vector3(0, -.35, 0))
		part(lg, cyl(.13, .13, .22), Color(.16, .11, .07), Vector3(0, -.65, .02))
		var am = Node3D.new(); am.position = Vector3(.38 * k, 1.42, 0); r.add_child(am); arms.append(am)
		part(am, cyl(.08, .07, .6), tun, Vector3(0, -.28, 0))
		part(am, sph(.075), skin, Vector3(.05 * k, -.6, 0))
		part(r, sph(.12), Color(.54, .56, .6), Vector3(.34 * k, 1.4, 0))
	part(r, cyl(.27, .33, .8), tun, Vector3(0, 1.05, 0))
	part(r, cyl(.34, .34, .09), Color(.48, .35, .16), Vector3(0, .72, 0))
	part(r, tor(.13, .27), Color(.75, .22, .17), Vector3(0, 1.45, 0))
	var cape = Node3D.new(); cape.position = Vector3(0, 1.48, -.24); r.add_child(cape)
	part(cape, box(.62, .95, .05), Color(.48, .12, .16), Vector3(0, -.47, 0))
	var tail = Node3D.new(); tail.position = Vector3(.1, 1.42, -.2); r.add_child(tail)
	part(tail, box(.1, .45, .04), Color(.75, .22, .17), Vector3(0, -.22, 0))
	part(r, sph(.25), skin, Vector3(0, 1.68, 0))
	var hm = SphereMesh.new(); hm.radius = .27; hm.height = .27; hm.is_hemisphere = true
	part(r, hm, Color(.23, .14, .08), Vector3(0, 1.74, -.04))
	face(r, 1.68, .225, 1.0, Color(.23, .16, .1), false)
	var sw = Node3D.new(); sw.position = Vector3(.5, 1.1, .2); r.add_child(sw)
	if external(r, "res://models/miliki.glb", [sw, cape, tail], Cfg.EXT.miliki):
		cape.visible = false; tail.visible = false; legs = []; arms = []
	return {"root": r, "sword": sw, "cape": cape, "tail": tail, "legs": legs, "arms": arms}
static func fuvu() -> Dictionary:
	var r = Node3D.new(); var rc = Color(.12, .23, .17)
	var body = part(r, cone(1.15, 3.0), rc, Vector3(0, 1.5, 0))
	part(r, tor(.55, .69), Color(.54, .42, .23), Vector3(0, 1.9, 0))
	part(r, sph(.5), rc, Vector3(-.75, 2.55, 0)).scale.y = .7
	part(r, sph(.42), Color(.72, .77, .6), Vector3(0, 3.2, 0))
	var hm = SphereMesh.new(); hm.radius = .5; hm.height = .5; hm.is_hemisphere = true
	part(r, hm, rc, Vector3(0, 3.4, -.07)).material_override = body.material_override
	face(r, 3.2, .37, 1.8, Color(1, .88, .25), true)
	for i in range(-2, 3):
		part(r, cone(.035, .1), Color(.96, .94, .88), Vector3(i * .065, 3.0, .4)).rotation.x = PI
	for k in [-1, 1]:
		part(r, cone(.12, .7), Color(.31, .6, .23), Vector3(.34 * k, 3.85, 0)).rotation.z = -.5 * k
	var arm = Node3D.new(); arm.position = Vector3(.9, 2.5, 0); r.add_child(arm)
	part(arm, cyl(.08, .08, 2.4), Color(.23, .19, .25), Vector3(0, 0, 1.2)).rotation.x = PI / 2
	var club = part(arm, sph(.5), Color(.31, .6, .23), Vector3(0, 0, 2.6)); club.scale.z = 2.2
	for i in 16:
		var a = i * 2.4
		part(club, sph(.06), Color(.18, .42, .16), Vector3(cos(a) * .5, sin(a) * .5, ((i % 8) - 3.5) * .11)).scale.z = .45
	external(r, "res://models/fuvu.glb", [arm], Cfg.EXT.fuvu)
	return {"root": r, "arm": arm, "club": club.material_override, "robe": body.material_override}

static func external(r: Node3D, path: String, keep: Array, sc: float = 1.0) -> bool:
	if not ResourceLoader.exists(path): return false
	for c in r.get_children():
		if not keep.has(c): c.queue_free()
	var m = load(path).instantiate(); m.scale = Vector3.ONE * sc; r.add_child(m); return true

static func weapon(n: String) -> Node3D:
	var w = Node3D.new(); var tip = Vector3(0, 0, 1.5); var col = Color(.6, .8, 1)
	match n:
		"espada":
			var bl = part(w, box(.07, .11, 1.15), Color(.87, .9, .94), Vector3(0, 0, .78)); bl.material_override.metallic = .95; bl.material_override.roughness = .2
			for k in [-1, 1]:
				part(w, box(.012, .05, .9), Color(.3, .5, .9), Vector3(.036 * k, 0, .75), Color(.15, .4, 1))
				part(w, sph(.035), Color(.72, .57, .23), Vector3(.17 * k, 0, .17))
			var tp = part(w, cyl(0.0, .065, .24), Color(.87, .9, .94), Vector3(0, 0, 1.45)); tp.mesh.radial_segments = 4; tp.scale.x = .55; tp.rotation.x = PI / 2
			part(w, box(.34, .05, .07), Color(.72, .57, .23), Vector3(0, 0, .17))
			part(w, cyl(.03, .03, .28), Color(.2, .12, .08), Vector3(0, 0, -.02)).rotation.x = PI / 2
			for i in 3: part(w, tor(.025, .04), Color(.5, .4, .2), Vector3(0, 0, -.1 + i * .08)).rotation.x = PI / 2
			part(w, sph(.055), Color(.2, .4, 1), Vector3(0, 0, -.17), Color(.1, .3, 1))
			col = Color(.7, .85, 1)
		"hacha":
			part(w, cyl(.035, .035, 1.4), Color(.4, .26, .14), Vector3(0, 0, .55)).rotation.x = PI / 2
			part(w, box(.07, .5, .3), Color(.55, .58, .62), Vector3(0, .05, 1.15))
			var ed = part(w, box(.04, .6, .12), Color(.85, .88, .92), Vector3(0, .05, 1.34)); ed.material_override.metallic = .95
			part(w, cone(.06, .3), Color(.55, .58, .62), Vector3(0, .05, .93)).rotation.x = -PI / 2
			for i in 3: part(w, cone(.07, .22), Color(.3, .65, .25), Vector3(.05, 0, .2 + i * .22), Color(.05, .2, .03)).rotation.z = -1.2
			tip = Vector3(0, .1, 1.4); col = Color(.6, .9, .5)
		_:
			part(w, cyl(.03, .03, .3), Color(.25, .15, .1), Vector3(0, 0, .05)).rotation.x = PI / 2
			part(w, sph(.045), Color(.72, .57, .23), Vector3(0, 0, -.12))
			part(w, box(.04, .08, .3), Color(.85, .88, .92), Vector3(0, 0, .35))
			part(w, box(.04, .07, .26), Color(.85, .88, .92), Vector3(0, -.04, .6)).rotation.x = .45
			part(w, box(.035, .06, .22), Color(.95, .97, 1), Vector3(0, -.17, .78)).rotation.x = .95
			tip = Vector3(0, -.25, .88); col = Color(.6, .85, 1)
	var tr = CPUParticles3D.new(); tr.name = "Trail"; tr.amount = 28; tr.lifetime = .28; tr.local_coords = false; tr.emitting = false
	tr.initial_velocity_max = .4; tr.gravity = Vector3.ZERO; tr.mesh = sph(.045); tr.material_override = mat(col, col); tr.position = tip; w.add_child(tr)
	return w

static func pepino(rich: bool = true) -> Node3D:
	var n = Node3D.new(); var gc = Color(.31, .62, .22)
	var body = part(n, sph(.3), gc, Vector3.ZERO, Color(.05, .25, .03)); body.scale = Vector3(.55, 1.5, .55)
	for i in 14:
		var a = i * 2.4
		part(body, sph(.03), Color(.18, .42, .16), Vector3(cos(a), ((i % 7) - 3) / 3.5, sin(a)).normalized() * .3)
	part(n, cyl(.03, .04, .14), Color(.25, .4, .12), Vector3(0, .5, 0))
	part(n, cone(.09, .22), Color(.3, .65, .25), Vector3(.08, .5, 0)).rotation.z = -1.2
	var h = part(n, tor(.5, .56), Color(1, .85, .3), Vector3.ZERO, Color(1, .75, .2)); h.rotation.x = .5; h.name = "Halo"
	var sp = CPUParticles3D.new(); sp.amount = 30; sp.lifetime = 1.2; sp.local_coords = false; sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE; sp.emission_sphere_radius = .4
	sp.gravity = Vector3(0, .6, 0); sp.initial_velocity_max = .3; sp.mesh = sph(.03); sp.material_override = mat(Color(1, .9, .4), Color(1, .85, .3)); n.add_child(sp)
	if rich:
		var l = OmniLight3D.new(); l.light_color = Color(.6, 1, .4); l.light_energy = 2.5; l.omni_range = 7.0; n.add_child(l)
	return n
