class_name ToyFactory
extends RefCounted

static var materials: Dictionary = {}

static func mat(color: Color, metallic: float = 0.0, glow: float = 0.0, roughness: float = 0.48, rim: bool = false) -> StandardMaterial3D:
	var key := str(color) + str(metallic) + str(glow) + str(roughness) + str(rim)
	if materials.has(key):
		return materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	m.clearcoat_enabled = true
	m.clearcoat = 0.28
	m.clearcoat_roughness = 0.18
	if rim:
		m.rim_enabled = true
		m.rim = 0.32
		m.rim_tint = 0.78
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glow > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	materials[key] = m
	return m

static func mesh(parent: Node3D, shape: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var obj := MeshInstance3D.new()
	obj.mesh = shape
	obj.material_override = mat(color)
	obj.position = at
	obj.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(obj)
	return obj

static func box(parent: Node3D, at: Vector3, size: Vector3, color: Color, solid: bool = false) -> Node3D:
	var shape := BoxMesh.new()
	shape.size = size
	if not solid:
		return mesh(parent, shape, at, color)
	var body := StaticBody3D.new()
	body.position = at
	parent.add_child(body)
	mesh(body, shape, Vector3.ZERO, color)
	var hit := CollisionShape3D.new()
	var collider := BoxShape3D.new()
	collider.size = size
	hit.shape = collider
	body.add_child(hit)
	return body

static func ball(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 32
	sphere.rings = 20
	var obj := mesh(parent, sphere, at, color)
	obj.scale = size
	return obj

static func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 32
	return mesh(parent, shape, at, color)

static func ring(parent: Node3D, at: Vector3, radius: float, thickness: float, color: Color) -> MeshInstance3D:
	var shape := TorusMesh.new()
	shape.inner_radius = radius - thickness
	shape.outer_radius = radius + thickness
	shape.rings = 32
	shape.ring_segments = 18
	return mesh(parent, shape, at, color)

static func glow_orb(parent: Node3D, at: Vector3, size: Vector3, color: Color, energy: float = 2.2) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 32
	sphere.rings = 20
	var obj := MeshInstance3D.new()
	obj.mesh = sphere
	obj.material_override = mat(color, 0.05, energy, 0.25, true)
	obj.position = at
	obj.scale = size
	obj.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(obj)
	return obj

static func accent_line(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return mesh(parent, shape, at, color)

static func egg(parent: Node3D, color: Color, accessory: int = 0) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	ball(root, Vector3(0, 0.78, 0), Vector3(1.18, 1.5, 1.06), color)
	ball(root, Vector3(0, 0.60, 0.36), Vector3(0.88, 0.80, 0.45), Color("fff6df"))
	# A layered face gives the mascot a crafted toy finish instead of a flat primitive.
	ball(root, Vector3(0, 0.87, 0.51), Vector3(0.38, 0.18, 0.09), Color("fffdf2"))
	for side in [-1, 1]:
		ball(root, Vector3(side * 0.24, 0.99, 0.492), Vector3(0.105, 0.17, 0.065), Color("25334b"))
		ball(root, Vector3(side * 0.25, 1.027, 0.522), Vector3.ONE * 0.026, Color.WHITE)
		ball(root, Vector3(side * 0.21, 1.055, 0.523), Vector3.ONE * 0.018, Color("bfe9ff"))
		ball(root, Vector3(side * 0.40, 0.82, 0.46), Vector3(0.20, 0.10, 0.04), Color("ff999f"))
		ball(root, Vector3(side * 0.64, 0.63, 0), Vector3(0.29, 0.37, 0.32), color)
		ball(root, Vector3(side * 0.32, 0.08, 0.10), Vector3(0.42, 0.20, 0.53), Color("fca34c"))
	ball(root, Vector3(0, 0.84, 0.564), Vector3(0.105, 0.055, 0.035), Color("763c46"))
	var scarf := ring(root, Vector3(0, 0.38, 0), 0.49, 0.065, Color("f66d81"))
	scarf.scale.y = 1.5
	box(root, Vector3(-0.29, 0.26, -0.46), Vector3(0.20, 0.38, 0.08), Color("f66d81"))
	var collar := ring(root, Vector3(0, 0.48, 0), 0.54, 0.035, Color("fff1c9"))
	collar.scale.y = 1.18
	box(root, Vector3(0, 0.46, 0.55), Vector3(0.24, 0.16, 0.05), Color("f4bd55"))
	glow_orb(root, Vector3(0, 0.48, 0.59), Vector3(0.075, 0.075, 0.075), Color("ffe697"), 1.3)
	# Tiny back patch and seam lines sell the character as an in-world costume.
	box(root, Vector3(0, 0.62, -0.53), Vector3(0.35, 0.31, 0.07), color.darkened(0.12))
	accent_line(root, Vector3(0, 0.62, -0.575), Vector3(0.18, 0.025, 0.015), Color("fff1c9"))
	if accessory % 3 == 0:
		cylinder(root, Vector3(0, 1.53, 0), 0.27, 0.12, Color("fff5cf"))
		for i in range(5):
			var angle := i * TAU / 5
			ball(root, Vector3(sin(angle) * 0.22, 1.65, cos(angle) * 0.22), Vector3(0.11, 0.23, 0.11), Color("ffcf54"))
	elif accessory % 3 == 1:
		for side in [-1, 1]:
			ball(root, Vector3(side * 0.23, 1.66, 0), Vector3(0.21, 0.66, 0.20), color)
			ball(root, Vector3(side * 0.23, 1.69, 0.085), Vector3(0.10, 0.40, 0.05), Color("ffb4c6"))
	else:
		cylinder(root, Vector3(0, 1.49, 0), 0.38, 0.10, Color("528c8d"))
		ball(root, Vector3(0, 1.57, 0), Vector3(0.52, 0.28, 0.52), Color("73b99c"))
	return root

static func label3d(parent: Node3D, text: String, at: Vector3, color: Color, font_size: int = 64) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = font_size
	label.pixel_size = 0.012
	label.modulate = color
	label.outline_size = 5
	label.outline_modulate = Color(0.15, 0.20, 0.3, 0.3)
	parent.add_child(label)
	return label

static func item_model(parent: Node3D, item: int, color: Color) -> Node3D:
	# Each pickup has a readable toy silhouette. The gameplay still treats the
	# returned root as one collectible, while the child meshes provide a clear
	# identity in the world and in screenshots.
	var root := Node3D.new()
	root.name = "ItemModel_%d" % item
	parent.add_child(root)
	var highlight := color.lightened(0.24)
	var shadow := color.darkened(0.22)
	match item:
		0: # Soda bottle: body, shoulder, neck and cap.
			cylinder(root, Vector3(0, 0.08, 0), 0.34, 0.64, color)
			ball(root, Vector3(0, 0.40, 0), Vector3(0.64, 0.32, 0.64), color)
			cylinder(root, Vector3(0, 0.61, 0), 0.17, 0.30, highlight)
			cylinder(root, Vector3(0, 0.79, 0), 0.21, 0.10, shadow)
			box(root, Vector3(0, 0.08, 0.345), Vector3(0.45, 0.20, 0.035), Color("fff2cf"))
			label3d(root, ">>", Vector3(0, 0.00, 0.372), Color("d86d57"), 28)
			glow_orb(root, Vector3(0, 0.88, 0), Vector3.ONE * 0.08, Color("fff3b7"), 1.5)
		1: # Bubble shield: transparent bubble with two luminous orbit rings.
			var bubble := ball(root, Vector3(0, 0.12, 0), Vector3(1.18, 1.18, 1.18), Color(color, 0.30))
			bubble.material_override = mat(Color(color, 0.30), 0.05, 1.3, 0.16, true)
			var orbit_a := ring(root, Vector3(0, 0.12, 0), 0.60, 0.045, highlight)
			orbit_a.rotation_degrees = Vector3(64, 0, 18)
			var orbit_b := ring(root, Vector3(0, 0.12, 0), 0.78, 0.035, Color("efffff"))
			orbit_b.rotation_degrees = Vector3(18, 68, 0)
			glow_orb(root, Vector3(-0.26, 0.43, 0.42), Vector3.ONE * 0.12, Color("ffffff"), 2.2)
			label3d(root, "O", Vector3(0, -0.01, 0.61), Color("ffffff"), 34)
		2: # Spring shoe: sole, toe, ankle cuff and a visible coil.
			box(root, Vector3(0, -0.18, 0.12), Vector3(0.80, 0.22, 1.00), shadow)
			ball(root, Vector3(0, 0.04, 0.23), Vector3(0.78, 0.40, 0.92), color)
			box(root, Vector3(0, 0.18, -0.28), Vector3(0.66, 0.52, 0.42), highlight)
			var spring := ring(root, Vector3(0, -0.48, 0.12), 0.25, 0.065, Color("fff2b2"))
			spring.rotation_degrees.x = 90
			cylinder(root, Vector3(0, -0.77, 0.12), 0.22, 0.16, Color("fff2b2"))
			label3d(root, "^^", Vector3(0, 0.28, 0.17), Color("ffffff"), 27)
		3: # Star magnet: horseshoe magnet with an orbiting star.
			cylinder(root, Vector3(-0.42, 0.10, 0), 0.17, 0.82, color)
			cylinder(root, Vector3(0.42, 0.10, 0), 0.17, 0.82, color)
			box(root, Vector3(0, -0.24, 0), Vector3(0.82, 0.28, 0.34), color)
			box(root, Vector3(-0.54, 0.05, 0), Vector3(0.22, 0.38, 0.28), Color("e75e75"))
			box(root, Vector3(0.54, 0.05, 0), Vector3(0.22, 0.38, 0.28), Color("5ba9de"))
			var star := PrismMesh.new()
			star.size = Vector3(0.44, 0.58, 0.18)
			mesh(root, star, Vector3(0, 0.58, 0), Color("ffe27d"))
			glow_orb(root, Vector3(0, 0.58, 0.12), Vector3.ONE * 0.07, Color("fff7ca"), 2.0)
			label3d(root, "★", Vector3(0, -0.16, 0.24), Color("ffffff"), 24)
		4: # Feather: shaft plus layered barbs and a floating tip.
			var shaft := cylinder(root, Vector3(0, 0.05, 0), 0.075, 1.35, shadow)
			shaft.rotation_degrees.z = -28
			for i in range(5):
				var t := float(i) / 4.0
				var y := -0.42 + t * 0.92
				var barb := ball(root, Vector3(-0.22 + t * 0.22, y, 0), Vector3(0.50 - t * 0.08, 0.12, 0.16), color)
				barb.rotation_degrees.z = -28
				var barb_r := ball(root, Vector3(0.22 - t * 0.10, y + 0.06, 0), Vector3(0.42 - t * 0.06, 0.11, 0.15), highlight)
				barb_r.rotation_degrees.z = -28
			glow_orb(root, Vector3(0.23, 0.68, 0), Vector3.ONE * 0.09, Color("f2fff8"), 1.8)
			label3d(root, "~", Vector3(0.03, -0.02, 0.15), Color("ffffff"), 27)
		5: # Rewind donut: torus, inner hub and a clearly visible rewind arrow.
			var donut := ring(root, Vector3(0, 0.05, 0), 0.48, 0.18, color)
			donut.rotation_degrees.x = 90
			var inner := glow_orb(root, Vector3(0, 0.05, 0), Vector3.ONE * 0.18, highlight, 1.4)
			inner.rotation_degrees.x = 90
			label3d(root, "↶", Vector3(-0.02, -0.02, 0.26), Color("ffffff"), 34)
			for side in [-1, 1]:
				glow_orb(root, Vector3(side * 0.76, 0.05, 0), Vector3.ONE * 0.075, highlight, 1.7)
			var halo := ring(root, Vector3(0, 0.05, 0), 0.82, 0.035, highlight)
			halo.rotation_degrees = Vector3(18, 0, 90)
	return root
