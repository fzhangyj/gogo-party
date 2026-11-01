class_name PartyCourse
extends Node3D

var map_index: int = 0
var data: Dictionary
var platforms: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var checkpoints: Array[Vector3] = []
var checkpoint_nodes: Array[Node3D] = []
var finish_position := Vector3.ZERO
var elapsed: float = 0.0
var active: bool = false
var stars_total: int = 0
var finish_ring: Node3D
var last_checkpoint: int = -1

func build(index: int) -> void:
	map_index = index
	data = CourseData.MAPS[index]
	var floor_color := Color(data.floor)
	var edge := Color(data.edge)
	var layout: Array = data.layout
	for i in range(layout.size()):
		var width: float = 12.0 if i == 0 or i == layout.size() - 1 else 9.8
		var depth: float = 15.5
		var pos := Vector3(float(layout[i]), float(data.heights[i]), -i * 19.0)
		var body := ToyFactory.box(self, pos - Vector3(0, 0.65, 0), Vector3(width, 1.3, depth), edge, true)
		ToyFactory.box(body, Vector3(0, 0.70, 0), Vector3(width + 0.04, 0.14, depth + 0.04), floor_color)
		# Repeated deck inlays make speed and jump distance readable.
		for row in range(5):
			for column in range(3):
				var tile_color := floor_color.lightened(0.14) if (row + column) % 2 == 0 else floor_color
				ToyFactory.box(body, Vector3((column - 1) * (width / 3.0), 0.79, (row - 2) * 3.0), Vector3(width / 3.0 - 0.09, 0.025, 2.91), tile_color)
		for side in [-1, 1]:
			ToyFactory.box(body, Vector3(side * (width / 2 - 0.10), 0.82, 0), Vector3(0.15, 0.12, depth), Color(data.accent))
		add_platform_details(body, width, depth, floor_color, edge, Color(data.accent))
		var record := {"body": body, "origin": body.position, "position": pos, "width": width, "depth": depth, "kind": data.kinds[i], "phase": i * 0.8}
		if record.kind == "crumble":
			var surfaces: Array[Dictionary] = []
			for child in body.get_children():
				if child is MeshInstance3D:
					surfaces.append({"node": child, "material": child.material_override})
			record["surfaces"] = surfaces
			record["warned"] = false
		platforms.append(record)
		if i == 0:
			make_start(pos)
		elif i == layout.size() - 1:
			finish_position = pos + Vector3(0, 0.5, -3.0)
			make_finish(finish_position)
		else:
			make_obstacle(str(data.kinds[i]), pos, i)
			if i % 2 == 0:
				make_checkpoint(pos + Vector3(0, 0.16, 4.8))
			for j in range(3):
				add_pickup(pos + Vector3(sin(j * 1.3 + i) * 2.5, 1.15, 4.0 - j * 3.8), "star", -1)
			add_pickup(pos + Vector3(-3.0 if i % 2 == 0 else 3.0, 1.0, 2.0), "item", (i - 1 + index) % CourseData.ITEMS.size())
		decorate(pos, i, width)
	make_background()

func add_platform_details(body: Node3D, width: float, depth: float, floor_color: Color, edge: Color, accent: Color) -> void:
	# Thin inlays and corner beacons create a finished, premium toy-set silhouette.
	for row in range(4):
		var z := -depth / 2.0 + 2.0 + row * 3.8
		ToyFactory.accent_line(body, Vector3(0, 0.823, z), Vector3(width - 0.65, 0.018, 0.035), floor_color.lightened(0.20))
	for side in [-1, 1]:
		for z in [-depth / 2.0 + 0.65, depth / 2.0 - 0.65]:
			ToyFactory.glow_orb(body, Vector3(side * (width / 2.0 - 0.34), 0.96, z), Vector3(0.10, 0.10, 0.10), Color("fff0a6"), 1.2)
		ToyFactory.accent_line(body, Vector3(side * (width / 2.0 - 0.26), 0.93, 0), Vector3(0.035, 0.05, depth - 0.7), accent.lightened(0.10))


func make_start(pos: Vector3) -> void:
	for i in range(12):
		ToyFactory.box(self, pos + Vector3(-5.5 + i, 0.17, -4.0), Vector3(0.95, 0.035, 0.65), Color.WHITE if i % 2 == 0 else Color(data.edge))
	ToyFactory.label3d(self, "GO!", pos + Vector3(0, 0.2, -2.5), Color.WHITE, 100).rotation_degrees.x = -90
	for side in [-1, 1]:
		ToyFactory.cylinder(self, pos + Vector3(side * 5, 2.3, -4.8), 0.16, 4.6, Color.WHITE)
		ToyFactory.glow_orb(self, pos + Vector3(side * 5, 4.7, -4.8), Vector3.ONE * 0.48, Color(data.accent), 1.8)
	ToyFactory.box(self, pos + Vector3(0, 4.1, -4.8), Vector3(10, 1.0, 0.35), Color(data.edge))
	ToyFactory.accent_line(self, pos + Vector3(0, 4.45, -4.62), Vector3(8.9, 0.035, 0.05), Color("fff2bb"))
	ToyFactory.label3d(self, "LET'S ROLL", pos + Vector3(0, 4.14, -4.59), Color.WHITE, 62)

func make_finish(pos: Vector3) -> void:
	finish_ring = Node3D.new()
	add_child(finish_ring)
	finish_ring.position = pos
	var ring := ToyFactory.ring(finish_ring, Vector3(0, 2.3, 0), 3.2, 0.25, Color("ffd46c"))
	ring.rotation_degrees.x = 90
	ToyFactory.ring(finish_ring, Vector3(0, 2.3, 0), 2.55, 0.055, Color("fff3b7"))
	for i in range(8):
		var angle := i * TAU / 8.0
		ToyFactory.glow_orb(finish_ring, Vector3(cos(angle) * 3.4, 2.3 + sin(angle) * 3.4, 0), Vector3.ONE * 0.14, Color("fff0a6"), 2.2)
	ToyFactory.label3d(finish_ring, "FINISH", Vector3(0, 6, 0), Color.WHITE, 95)
	for i in range(10):
		ToyFactory.box(self, pos + Vector3(-4.5 + i, -0.31, 0), Vector3(0.98, 0.04, 1.1), Color.WHITE if i % 2 == 0 else Color(data.edge))
	for side in [-1, 1]:
		ToyFactory.cylinder(self, pos + Vector3(side * 4.6, 1.6, 0), 0.16, 4.1, Color.WHITE)
		ToyFactory.ball(self, pos + Vector3(side * 4.6, 3.9, 0), Vector3(1.1, 1.35, 1.1), Color(data.color))

func make_checkpoint(pos: Vector3) -> void:
	checkpoints.append(pos + Vector3(0, 1.2, 0))
	var flag := Node3D.new()
	add_child(flag)
	flag.position = pos
	ToyFactory.ring(flag, Vector3.ZERO, 1.0, 0.10, Color("a4ead5"))
	ToyFactory.ring(flag, Vector3(0, 0.02, 0), 0.72, 0.035, Color("f1fff6"))
	ToyFactory.glow_orb(flag, Vector3(0, 0.28, 0), Vector3.ONE * 0.11, Color("baffdf"), 2.1)
	ToyFactory.cylinder(flag, Vector3(4.1, 1.2, 0), 0.08, 2.5, Color.WHITE)
	ToyFactory.box(flag, Vector3(4.65, 2.05, 0), Vector3(1.1, 0.65, 0.07), Color("71bda6"))
	ToyFactory.accent_line(flag, Vector3(4.65, 2.05, 0.05), Vector3(0.70, 0.03, 0.02), Color("e4fff3"))
	checkpoint_nodes.append(flag)

func make_obstacle(kind: String, pos: Vector3, index: int) -> void:
	var pivot := Node3D.new()
	pivot.position = pos
	add_child(pivot)
	match kind:
		"sweeper":
			ToyFactory.cylinder(pivot, Vector3(0, 0.55, 0), 0.53, 1.1, Color(data.accent))
			var arm := Node3D.new()
			pivot.add_child(arm)
			ToyFactory.box(arm, Vector3(0, 0.70, 0), Vector3(8.8, 0.38, 0.45), Color("f77e94"))
			for side in [-1, 1]:
				ToyFactory.ball(arm, Vector3(side * 4.4, 0.70, 0), Vector3.ONE * 0.62, Color("fff5dc"))
			hazards.append({"kind": kind, "node": arm, "center": pos, "speed": 1.1 + map_index * 0.1})
		"bumper":
			for j in range(3):
				var point := pos + Vector3((j - 1) * 3.0, 0.8, (j % 2) * -3.0)
				ToyFactory.cylinder(self, point - Vector3(0, 0.45, 0), 0.70, 0.6, Color(data.edge))
				var bumper := ToyFactory.ball(self, point, Vector3(1.7, 1.6, 1.7), Color(data.accent))
				hazards.append({"kind": "bumper", "node": bumper, "center": point, "radius": 1.1})
		"gate":
			for side in [-1, 1]:
				var gate := ToyFactory.box(pivot, Vector3(side * 3.3, 1.0, 0), Vector3(3.2, 2.0, 0.7), Color(data.edge))
				ToyFactory.box(gate, Vector3(0, 0, 0.37), Vector3(2.85, 0.20, 0.04), Color(data.accent))
				hazards.append({"kind": "gate", "node": gate, "center": pos, "side": side, "phase": index * 0.7})
		"fire":
			for side in [-1, 1]:
				var point := pos + Vector3(side * 2.2, 0, 0)
				ToyFactory.cylinder(self, point + Vector3(0, 0.15, 0), 1.1, 0.22, Color("e39662"))
				var jet := ToyFactory.cylinder(self, point + Vector3(0, 1.3, 0), 0.60, 2.6, Color("ffb758"))
				hazards.append({"kind": kind, "node": jet, "center": point, "phase": index + side * 0.7})
		"pendulum":
			for side in [-1, 1]:
				ToyFactory.cylinder(pivot, Vector3(side * 4.4, 3.2, 0), 0.18, 6.4, Color("b88d69"))
			ToyFactory.box(pivot, Vector3(0, 6.2, 0), Vector3(9, 0.3, 0.4), Color("b88d69"))
			var swing := Node3D.new()
			pivot.add_child(swing)
			swing.position.y = 6.0
			ToyFactory.cylinder(swing, Vector3(0, -2.2, 0), 0.065, 4.4, Color("e1d7ad"))
			ToyFactory.ball(swing, Vector3(0, -4.7, 0), Vector3(2.0, 1.7, 1.7), Color("be815f"))
			hazards.append({"kind": kind, "node": swing, "center": pos, "phase": index})
		"bounce":
			ToyFactory.cylinder(pivot, Vector3(0, 0.16, -2), 1.65, 0.32, Color("61bfae"))
			ToyFactory.ring(pivot, Vector3(0, 0.34, -2), 1.45, 0.11, Color("c1ffe1"))
			ToyFactory.label3d(pivot, "^^", Vector3(0, 0.36, -2), Color.WHITE, 65).rotation_degrees.x = -90
			hazards.append({"kind": kind, "node": pivot, "center": pos + Vector3(0, 0, -2)})
		"conveyor", "wind":
			for j in range(5):
				ToyFactory.label3d(pivot, ">>" if kind == "wind" else "^^", Vector3(0, 0.20, (j - 2) * 2.4), Color(data.edge), 78).rotation_degrees.x = -90
			hazards.append({"kind": kind, "node": pivot, "center": pos})
		"crumble":
			ToyFactory.label3d(pivot, "!", Vector3(0, 0.22, 0), Color("ffdb92"), 150).rotation_degrees.x = -90

func add_pickup(pos: Vector3, kind: String, item: int) -> void:
	var root := Node3D.new()
	add_child(root)
	root.position = pos
	if kind == "star":
		var gem := PrismMesh.new()
		gem.size = Vector3(0.65, 0.85, 0.26)
		ToyFactory.mesh(root, gem, Vector3.ZERO, Color("ffcf54"))
		var bottom := ToyFactory.mesh(root, gem, Vector3(0, -0.28, 0), Color("ffe392"))
		bottom.rotation.z = PI
		ToyFactory.glow_orb(root, Vector3(0, -0.02, 0), Vector3.ONE * 0.11, Color("fff2ae"), 1.6)
		stars_total += 1
	else:
		var color := Color(CourseData.ITEMS[item].color)
		ToyFactory.item_model(root, item, color)
		# A small pedestal ring keeps the pickup readable against every map floor.
		var pedestal := ToyFactory.ring(root, Vector3(0, -0.72, 0), 0.62, 0.045, color.lightened(0.12))
		pedestal.rotation_degrees.x = 90
	pickups.append({"node": root, "kind": kind, "item": item, "origin": pos, "collected": false})

func decorate(pos: Vector3, index: int, width: float) -> void:
	for side in [-1, 1]:
		var p := pos + Vector3(side * (width / 2 + 2.4), -1.0, -1.0)
		match map_index:
			0:
				ToyFactory.cylinder(self, p + Vector3(0, 2, 0), 0.12, 4, Color("fff0d8"))
				var candy := ToyFactory.ball(self, p + Vector3(0, 4, 0), Vector3(2.6, 2.6, 0.9), Color("f894b2") if index % 2 == 0 else Color("b5a3e4"))
				var spiral := ToyFactory.ring(candy, Vector3(0, 0, 0.49), 0.31, 0.075, Color("fff2e1"))
				spiral.rotation_degrees.x = 90
			1:
				ToyFactory.ball(self, p + Vector3(0, 0.8, 0), Vector3(2.5, 2.3, 2.5), Color("f4fbff"))
				ToyFactory.ball(self, p + Vector3(0, 2.3, 0), Vector3.ONE * 1.65, Color("f4fbff"))
				for eye in [-1, 1]:
					ToyFactory.ball(self, p + Vector3(eye * 0.28, 2.5, 0.76), Vector3.ONE * 0.12, Color("506480"))
			2:
				var rock := ToyFactory.ball(self, p, Vector3(3, 5.4, 3), Color("695976"))
				rock.rotation_degrees.z = side * 18
				ToyFactory.ball(self, p + Vector3(0, 2.5, 0), Vector3(1.0, 0.6, 1), Color("ffb467"))
			3:
				for j in range(3):
					ToyFactory.ball(self, p + Vector3(j - 1, sin(j) * 0.5, 0), Vector3(3, 1.6, 2.7), Color("fff9ff"))
			4:
				ToyFactory.cylinder(self, p + Vector3(0, 1.2, 0), 0.4, 2.4, Color("fae6c0"))
				ToyFactory.ball(self, p + Vector3(0, 2.5, 0), Vector3(3.4, 1.5, 3.4), Color("ed9c85"))
				for j in range(4):
					ToyFactory.ball(self, p + Vector3(sin(j * 1.5), 3.05, cos(j * 1.5)), Vector3(0.45, 0.13, 0.45), Color("fff1d5"))
			5:
				ToyFactory.ball(self, p + Vector3(0, 2, 0), Vector3.ONE * 2.5, Color("c5a4d8"))
				var ring := ToyFactory.ring(self, p + Vector3(0, 2, 0), 1.9, 0.10, Color("ffe1a0"))
				ring.rotation_degrees.z = side * 25

func make_background() -> void:
	for i in range(15):
		var side: int = -1 if i % 2 == 0 else 1
		var p := Vector3(side * (19.0 + (i % 3) * 6), -5.0 - i % 4, -i * 10.0)
		for j in range(3):
			ToyFactory.ball(self, p + Vector3((j - 1) * 2, j % 2, 0), Vector3(7, 3, 5), Color(data.sky).lightened(0.20))
	if map_index == 2:
		ToyFactory.box(self, Vector3(0, -7, -65), Vector3(160, 0.5, 220), Color("df836e"))

func tick(delta: float, runner: CharacterBody3D = null) -> void:
	elapsed += delta
	for platform in platforms:
		var body: Node3D = platform.body
		if platform.kind == "moving":
			var old_x := body.position.x
			body.position.x = platform.origin.x + sin(elapsed * 1.1 + platform.phase) * 1.7
			if runner != null and runner.is_on_floor() and on_platform(runner.position, platform):
				runner.position.x += body.position.x - old_x
		elif platform.kind == "crumble":
			var phase := fmod(elapsed + platform.phase, 5.0)
			var warning: bool = phase > 3.0 and phase < 3.9
			if warning != platform.warned:
				platform.warned = warning
				for surface in platform.surfaces:
					surface.node.material_override = ToyFactory.mat(Color("ef9972")) if warning else surface.material
			body.visible = phase < 3.9
			body.collision_layer = 1 if body.visible else 0
			body.position.y = platform.origin.y + (sin(elapsed * 38) * 0.035 if phase > 3.0 and phase < 3.9 else 0.0)
	for hazard in hazards:
		var node: Node3D = hazard.node
		match hazard.kind:
			"sweeper": node.rotation.y = elapsed * hazard.speed
			"gate": node.position.x = hazard.side * (3.25 + sin(elapsed * 1.65 + hazard.phase) * 1.05)
			"pendulum": node.rotation.z = sin(elapsed * 1.55 + hazard.phase) * 0.85
			"fire":
				node.visible = fmod(elapsed + hazard.phase, 3.6) < 1.65
				node.scale.y = 0.85 + sin(elapsed * 16) * 0.15
	for pick in pickups:
		if not pick.collected:
			pick.node.rotation.y += delta * 1.2
			pick.node.position.y = pick.origin.y + sin(elapsed * 2.5 + pick.origin.z) * 0.17
	if runner != null and active:
		interact(runner, delta)

func on_platform(p: Vector3, platform: Dictionary) -> bool:
	var b: Vector3 = platform.body.position
	return absf(p.x - b.x) < platform.width / 2 and absf(p.z - b.z) < platform.depth / 2 and absf(p.y - (b.y + 0.65)) < 0.5

func interact(runner: CharacterBody3D, delta: float) -> void:
	for pick in pickups:
		if pick.collected:
			continue
		var distance: float = runner.position.distance_to(pick.node.position)
		if pick.kind == "star" and runner.effects.get("magnet", 0.0) > 0 and distance < 7.0:
			pick.node.position = pick.node.position.move_toward(runner.position + Vector3.UP * 0.7, delta * 19)
			distance = runner.position.distance_to(pick.node.position)
		if distance < 1.75 and (pick.kind == "star" or runner.held_item < 0):
			pick.collected = true
			pick.node.hide()
			runner.collect(pick.kind, pick.item)
	for i in range(checkpoints.size()):
		if i > last_checkpoint and runner.is_on_floor() and runner.position.distance_to(checkpoints[i]) < 3.2:
			last_checkpoint = i
			runner.checkpoint = checkpoints[i]
			runner.checkpoint_reached.emit(i + 1)
	for hazard in hazards:
		var p: Vector3 = runner.position
		var center: Vector3 = hazard.center
		var near := absf(p.z - center.z) < 5.0 and absf(p.x - center.x) < 6.0
		if not near:
			continue
		match hazard.kind:
			"sweeper":
				var local: Vector3 = hazard.node.to_local(p + Vector3.UP * 0.55)
				if absf(local.x) < 4.9 and absf(local.z) < 0.58 and local.y > 0.05 and local.y < 1.3:
					runner.hit((p - center).normalized() * 10 + Vector3.UP * 6)
			"bumper":
				if (p + Vector3.UP * 0.65).distance_to(center) < 1.35:
					runner.hit((p - center).normalized() * 12 + Vector3.UP * 7)
			"gate":
				var local: Vector3 = hazard.node.to_local(p)
				if absf(local.x) < 2.0 and absf(local.z) < 0.7 and local.y < 1.3 and local.y > -1.5:
					runner.hit(Vector3(hazard.side * -8, 5, 7))
			"fire":
				if hazard.node.visible and Vector2(p.x - center.x, p.z - center.z).length() < 1.15 and p.y < center.y + 2.6:
					runner.hit(Vector3(6 if p.x > center.x else -6, 7, 5))
			"pendulum":
				var ball_pos: Vector3 = hazard.node.to_global(Vector3(0, -4.7, 0))
				if (p + Vector3.UP * 0.7).distance_to(ball_pos) < 1.55:
					runner.hit((p - ball_pos).normalized() * 12 + Vector3.UP * 5)
			"bounce":
				if Vector2(p.x - center.x, p.z - center.z).length() < 1.7 and p.y < center.y + 0.55 and runner.velocity.y <= 0:
					runner.velocity.y = 14.0
					runner.bounced.emit()
			"wind":
				if absf(p.z - center.z) < 6.3 and p.y < center.y + 5:
					runner.velocity.x += delta * 8
			"conveyor":
				if runner.is_on_floor() and absf(p.z - center.z) < 6.3:
					runner.position.z += delta * 2.7
	if runner.position.z < finish_position.z + 1.0 and absf(runner.position.x - finish_position.x) < 5.7 and absf(runner.position.y - finish_position.y) < 3.5:
		runner.finished.emit()
