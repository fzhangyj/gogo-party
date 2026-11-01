extends Node3D

const INK := Color("2d4355")
const MUTED := Color("71808d")
const CORAL := Color("ee806c")
const PAPER := Color("fffdf6")
const SAVE_PATH := "user://gogo_records.cfg"

var world: PartyCourse
var player: PartyRunner
var camera: Camera3D
var environment: WorldEnvironment
var sound: PartySound
var lobby_stage: Node3D
var ui: Control
var lobby_ui: Control
var hud: Control
var modal: Control
var toast_label: Label
var toast_left: float = 0
var font: SystemFont
var bold: SystemFont
var selected_map: int = 0
var selected_skin: int = 0
var state: String = "lobby"
var race_time: float = 0.0
var countdown: float = 3.4
var last_count: int = -1
var title_label: Label
var desc_label: Label
var badge_label: Label
var best_label: Label
var time_label: Label
var stars_label: Label
var checkpoint_label: Label
var item_label: Label
var effects_label: Label
var roll_label: Label
var count_label: Label
var progress_fill: Panel
var map_buttons: Array[Button] = []
var skin_buttons: Array[Button] = []
var save := ConfigFile.new()
var confetti: Array[Dictionary] = []
var demo_capture: bool = false
var capture_dir: String = ""
var overall_time: float = 0.0
var persist_records: bool = true

func _ready() -> void:
	register_inputs()
	save.load(SAVE_PATH)
	selected_skin = clampi(int(save.get_value("settings", "skin", 0)), 0, CourseData.SKINS.size() - 1)
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "Noto Sans CJK SC", "sans-serif"])
	bold = SystemFont.new()
	bold.font_names = font.font_names
	bold.font_weight = 700
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 18
	ThemeDB.fallback_font = font
	create_environment()
	player = PartyRunner.new()
	add_child(player)
	player.set_skin(selected_skin)
	player.collected.connect(on_collected)
	player.checkpoint_reached.connect(on_checkpoint)
	player.fell.connect(on_fall)
	player.finished.connect(finish_race)
	player.jumped.connect(func(): sound.play("jump"))
	player.bounced.connect(func(): sound.play("jump"))
	player.item_used.connect(on_item_used)
	sound = PartySound.new()
	add_child(sound)
	sound.enabled = bool(save.get_value("settings", "sound", true))
	var canvas := CanvasLayer.new()
	add_child(canvas)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = theme
	canvas.add_child(ui)
	show_lobby()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_dir = arg.trim_prefix("--capture=")
			demo_capture = true
			capture_screens()

func register_inputs() -> void:
	var bindings := {
		"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE], "roll": [KEY_SHIFT], "use_item": [KEY_E],
		"respawn": [KEY_R], "pause_game": [KEY_ESCAPE]
	}
	for action in bindings:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func create_environment() -> void:
	environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("bde4f3")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f2f5ff")
	env.ambient_light_energy = 0.24
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = Color("bde4f3")
	env.fog_density = 0.0032
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_color = Color("fff0d9")
	sun.light_energy = 0.38
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 100
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 150, 0)
	fill.light_color = Color("d8efff")
	fill.light_energy = 0.08
	add_child(fill)
	camera = Camera3D.new()
	camera.current = true
	camera.far = 320
	add_child(camera)

func clear_ui() -> void:
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	modal = null
	toast_label = null
	map_buttons.clear()
	skin_buttons.clear()

func rebuild_world(index: int) -> void:
	if is_instance_valid(world):
		remove_child(world)
		world.queue_free()
	world = PartyCourse.new()
	add_child(world)
	world.build(index)
	var sky := Color(CourseData.MAPS[index].sky)
	environment.environment.background_color = sky
	environment.environment.fog_light_color = sky
	if is_instance_valid(lobby_stage):
		remove_child(lobby_stage)
		lobby_stage.queue_free()

func show_lobby() -> void:
	state = "lobby"
	player.control_enabled = false
	player.visible = true
	clear_ui()
	rebuild_world(selected_map)
	create_lobby_stage()
	set_lobby_camera()
	lobby_ui = Control.new()
	lobby_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lobby_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(lobby_ui)
	var gradient := Gradient.new()
	gradient.set_color(0, Color("f8f6ef"))
	gradient.set_color(1, Color(0.97, 0.97, 0.94, 0))
	gradient.add_point(0.60, Color(0.975, 0.974, 0.95, 0.97))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2.RIGHT
	var veil := TextureRect.new()
	veil.texture = texture
	veil.position = Vector2.ZERO
	veil.size = Vector2(740, 700)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lobby_ui.add_child(veil)
	panel(lobby_ui, Rect2(0, 760, 1440, 140), PAPER, 0)
	var logo := panel(lobby_ui, Rect2(48, 34, 46, 46), CORAL, 16)
	text_label(logo, "g", Rect2(0, -5, 46, 50), 37, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	text_label(lobby_ui, "GOGO PARTY", Rect2(106, 37, 200, 37), 25, INK, true)
	text_label(lobby_ui, "一起滚进快乐里", Rect2(307, 45, 170, 25), 15, MUTED)
	button(lobby_ui, "道具图鉴", Rect2(1070, 35, 136, 46), show_guide, Color(1, 1, 1, 0.85), INK, 16)
	button(lobby_ui, "声音：开" if sound.enabled else "声音：关", Rect2(1220, 35, 170, 46), toggle_sound, Color(1, 1, 1, 0.85), INK, 16).name = "SoundButton"
	text_label(lobby_ui, "小小身体，大大冒险", Rect2(53, 141, 400, 35), 21, Color("bc715d"), true)
	text_label(lobby_ui, "滚滚奇遇", Rect2(43, 175, 590, 135), 103, INK, true)
	text_label(lobby_ui, "下一站，快乐！", Rect2(51, 309, 510, 66), 40, INK, true)
	text_label(lobby_ui, "穿过奇妙关卡，收集星星，\n和圆滚滚的自己一起冲向终点。", Rect2(54, 391, 480, 70), 23, MUTED)
	panel(lobby_ui, Rect2(55, 486, 304, 39), Color("e8ebdf"), 19)
	text_label(lobby_ui, "6 张主题地图  /  6 种奇趣道具", Rect2(55, 491, 304, 28), 16, Color("657c65"), true, HORIZONTAL_ALIGNMENT_CENTER)
	var map_info := panel(lobby_ui, Rect2(680, 443, 300, 104), Color(1, 0.99, 0.95, 0.92), 22)
	badge_label = text_label(map_info, "", Rect2(20, 13, 300, 24), 12, Color("9b7364"), true)
	title_label = text_label(map_info, "", Rect2(20, 40, 310, 42), 26, INK, true)
	desc_label = text_label(map_info, "", Rect2(20, 76, 260, 22), 12, MUTED)
	text_label(lobby_ui, "挑一张地图，出发吧", Rect2(53, 562, 440, 40), 25, INK, true)
	text_label(lobby_ui, "全部开放 · 单人计时挑战", Rect2(1018, 570, 371, 25), 15, MUTED, false, HORIZONTAL_ALIGNMENT_RIGHT)
	for i in range(CourseData.MAPS.size()):
		create_map_card(i)
	text_label(lobby_ui, "今天的你", Rect2(55, 810, 116, 25), 16, MUTED)
	for i in range(CourseData.SKINS.size()):
		var b := button(lobby_ui, "", Rect2(165 + i * 50, 801, 39, 39), select_skin.bind(i), CourseData.SKINS[i], INK, 18)
		skin_buttons.append(b)
	best_label = text_label(lobby_ui, "", Rect2(485, 813, 305, 29), 17, MUTED)
	button(lobby_ui, "玩法说明", Rect2(877, 799, 147, 57), show_help, Color("eaf0ef"), INK, 18)
	button(lobby_ui, "开始冒险   →", Rect2(1040, 786, 350, 79), start_race, CORAL, Color.WHITE, 27)
	refresh_selection()
	create_toast()

func create_map_card(index: int) -> void:
	var data: Dictionary = CourseData.MAPS[index]
	var b := button(lobby_ui, "", Rect2(52 + index * 224, 612, 212, 156), select_map.bind(index), PAPER, INK, 18)
	b.tooltip_text = data.desc
	map_buttons.append(b)
	var preview := MapPreview.new()
	preview.map_index = index
	preview.position = Vector2(7, 7)
	preview.size = Vector2(198, 101)
	b.add_child(preview)
	text_label(b, data.name, Rect2(12, 116, 159, 26), 17, INK, true)
	text_label(b, "●".repeat(data.difficulty), Rect2(155, 120, 44, 22), 10, Color(data.color), true, HORIZONTAL_ALIGNMENT_RIGHT)
	text_label(b, "MAP %02d" % (index + 1), Rect2(151, 12, 48, 18), 10, Color(data.edge), true, HORIZONTAL_ALIGNMENT_RIGHT)

func create_lobby_stage() -> void:
	lobby_stage = Node3D.new()
	add_child(lobby_stage)
	ToyFactory.cylinder(lobby_stage, Vector3(10.5, 2.15, -3), 4.0, 1.5, Color("fff5d8"))
	ToyFactory.ring(lobby_stage, Vector3(10.5, 2.95, -3), 3.7, 0.13, Color("f6c777"))
	var halo := ToyFactory.ring(lobby_stage, Vector3(10.5, 6.4, -5.0), 3.15, 0.12, Color("fff0ad"))
	halo.rotation_degrees.x = 90
	ToyFactory.ring(lobby_stage, Vector3(10.5, 6.4, -5.0), 2.72, 0.045, Color("ffffff"))
	ToyFactory.label3d(lobby_stage, "GOGO CLUB", Vector3(10.5, 8.0, -5.0), Color("fff8e1"), 48)
	for side in [-1, 1]:
		ToyFactory.cylinder(lobby_stage, Vector3(10.5 + side * 5.8, 3.7, -5.2), 0.065, 3.0, Color("f6e5bd"))
		ToyFactory.glow_orb(lobby_stage, Vector3(10.5 + side * 5.8, 5.25, -5.2), Vector3.ONE * 0.20, Color("ffe89c"), 2.0)
	player.position = Vector3(10.5, 3.0, -3)
	player.velocity = Vector3.ZERO
	player.visual.rotation = Vector3(0, 0.1, 0)
	player.visual.scale = Vector3.ONE * 3.2
	player.visual.visible = true
	player.shield_visual.hide()
	var friend := ToyFactory.egg(lobby_stage, Color("9fd7c4"), 2)
	friend.position = Vector3(6.8, 3.0, -5)
	friend.rotation.y = 0.40
	friend.scale = Vector3.ONE * 1.5
	var bunny := ToyFactory.egg(lobby_stage, Color("f5a4c1"), 1)
	bunny.position = Vector3(14.0, 3.0, -5)
	bunny.rotation.y = -0.4
	bunny.scale = Vector3.ONE * 1.35
	for i in range(3):
		var pos := Vector3(14.8 + i * 0.8, 7.1 + i * 1.25, -9 - i)
		ToyFactory.cylinder(lobby_stage, pos - Vector3(0, 2.0, 0), 0.018, 4, Color("eee4d4"))
		ToyFactory.ball(lobby_stage, pos, Vector3(1.35, 1.65, 1.35), [Color("ffbbad"), Color("fff0ae"), Color("b7c5eb")][i])

func set_lobby_camera() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 26.0
	camera.position = Vector3(16.5, 17.2, 29)
	camera.look_at(Vector3(-4.0, 0.5, -5))

func select_map(index: int) -> void:
	selected_map = index
	sound.play("click")
	rebuild_world(index)
	create_lobby_stage()
	refresh_selection()

func select_skin(index: int) -> void:
	selected_skin = index
	player.set_skin(index)
	player.visual.scale = Vector3.ONE * 3.2
	save.set_value("settings", "skin", index)
	if persist_records: save.save(SAVE_PATH)
	sound.play("click")
	refresh_selection()

func refresh_selection() -> void:
	var data: Dictionary = CourseData.MAPS[selected_map]
	title_label.text = data.name
	badge_label.text = "%02d / %s" % [selected_map + 1, data.en]
	desc_label.text = data.tag + "   ·   " + "★".repeat(data.difficulty)
	for i in range(map_buttons.size()):
		var style := rounded(PAPER, 20)
		style.border_color = CORAL if i == selected_map else Color("e1e7e7")
		style.set_border_width_all(3 if i == selected_map else 1)
		map_buttons[i].add_theme_stylebox_override("normal", style)
	for i in range(skin_buttons.size()):
		var style := rounded(CourseData.SKINS[i], 20)
		style.border_color = INK if i == selected_skin else Color.WHITE
		style.set_border_width_all(3)
		skin_buttons[i].add_theme_stylebox_override("normal", style)
		skin_buttons[i].text = "✓" if i == selected_skin else ""
	var best := float(save.get_value("records", str(selected_map), 0.0))
	best_label.text = "个人最佳  " + format_time(best) if best > 0 else "首次挑战，写下你的纪录"

func toggle_sound() -> void:
	sound.enabled = not sound.enabled
	save.set_value("settings", "sound", sound.enabled)
	if persist_records: save.save(SAVE_PATH)
	if is_instance_valid(lobby_ui):
		var b := lobby_ui.get_node_or_null("SoundButton")
		if b != null: b.text = "声音：开" if sound.enabled else "声音：关"
	sound.play("click")

func start_race() -> void:
	sound.play("click")
	clear_ui()
	rebuild_world(selected_map)
	player.reset(Vector3(0, 0.30, 3.5), CourseData.MAPS[selected_map])
	player.control_enabled = false
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 65
	camera.position = player.position + Vector3(0, 8.5, 13)
	camera.look_at(player.position + Vector3(0, 0.9, -4))
	race_time = 0
	countdown = 3.4
	last_count = -1
	state = "countdown"
	create_hud()
	toast(CourseData.MAPS[selected_map].tip, 6)

func create_hud() -> void:
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hud)
	var map_panel := panel(hud, Rect2(32, 30, 327, 86), Color(1, 0.99, 0.97, 0.94), 20)
	text_label(map_panel, "%02d  %s" % [selected_map + 1, CourseData.MAPS[selected_map].name], Rect2(20, 12, 290, 33), 23, INK, true)
	checkpoint_label = text_label(map_panel, "出发！寻找绿色复活旗", Rect2(21, 52, 284, 22), 14, MUTED)
	panel(hud, Rect2(514, 30, 411, 83), Color(1, 0.99, 0.97, 0.94), 20)
	time_label = text_label(hud, "00:00.00", Rect2(528, 40, 189, 46), 33, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	stars_label = text_label(hud, "★  0 / %d" % world.stars_total, Rect2(736, 42, 173, 37), 24, Color("b18131"), true, HORIZONTAL_ALIGNMENT_CENTER)
	var progress_track := panel(hud, Rect2(545, 94, 350, 6), Color("e5e8e2"), 3)
	progress_fill = panel(progress_track, Rect2(0, 0, 0, 6), CORAL, 3)
	button(hud, "暂停  Esc", Rect2(1245, 30, 163, 50), pause_game, PAPER, INK, 17)
	panel(hud, Rect2(32, 790, 589, 79), Color(1, 0.99, 0.97, 0.94), 18)
	text_label(hud, "W A S D / 方向键", Rect2(53, 803, 180, 25), 16, INK, true)
	text_label(hud, "移动", Rect2(53, 838, 180, 20), 13, MUTED)
	text_label(hud, "空格", Rect2(259, 803, 90, 25), 16, INK, true)
	text_label(hud, "跳跃", Rect2(259, 838, 90, 20), 13, MUTED)
	text_label(hud, "Shift", Rect2(372, 803, 90, 25), 16, INK, true)
	roll_label = text_label(hud, "滚动就绪", Rect2(372, 838, 110, 20), 13, MUTED)
	text_label(hud, "R", Rect2(505, 803, 70, 25), 16, INK, true)
	text_label(hud, "回到复活点", Rect2(495, 838, 110, 20), 13, MUTED)
	panel(hud, Rect2(1114, 762, 294, 105), Color(1, 0.99, 0.97, 0.96), 20)
	text_label(hud, "随身道具", Rect2(1134, 776, 190, 25), 14, MUTED)
	item_label = text_label(hud, "等待拾取", Rect2(1134, 811, 181, 39), 23, INK, true)
	button(hud, "E", Rect2(1335, 795, 49, 48), func():
		if state == "racing": player.use_item(), CORAL, Color.WHITE, 23)
	effects_label = text_label(hud, "", Rect2(810, 717, 590, 32), 18, INK, true, HORIZONTAL_ALIGNMENT_RIGHT)
	count_label = text_label(hud, "3", Rect2(520, 286, 400, 177), 112, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	count_label.add_theme_constant_override("outline_size", 12)
	count_label.add_theme_color_override("font_outline_color", Color("c78276"))
	create_toast()

func _process(delta: float) -> void:
	overall_time += delta
	if not is_instance_valid(world): return
	if state == "lobby":
		world.tick(delta)
		player.visual.position.y = sin(overall_time * 1.8) * 0.12
		player.visual.rotation.z = sin(overall_time * 1.3) * 0.035
	elif state == "countdown":
		world.tick(delta)
		countdown -= delta
		var number := ceili(countdown)
		count_label.text = str(mini(number, 3)) if number > 0 else "GO!"
		if number != last_count:
			last_count = number
			sound.play("count")
		if countdown < -0.45:
			state = "racing"
			world.active = true
			player.control_enabled = true
			count_label.hide()
	elif state == "racing":
		race_time += delta
		world.tick(delta, player)
		update_hud()
		var target := player.position + Vector3(0, 8.5, 13)
		camera.position = camera.position.lerp(target, 1 - exp(-delta * 6.5))
		camera.look_at(player.position + Vector3(0, 0.9, -4))
	elif state == "finished":
		for bit in confetti:
			bit.node.position += bit.velocity * delta
			bit.velocity.y += delta * 170
			bit.node.rotation += delta * bit.spin
	if toast_left > 0 and is_instance_valid(toast_label):
		toast_left -= delta
		toast_label.modulate.a = clampf(toast_left * 2, 0, 1)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		if state == "paused": resume_game()
		elif state == "racing" or state == "countdown": pause_game()
		elif state == "lobby" and is_instance_valid(modal): close_modal()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func update_hud() -> void:
	time_label.text = format_time(race_time)
	stars_label.text = "★  %d / %d" % [player.stars, world.stars_total]
	progress_fill.size.x = clampf((3.5 - player.position.z) / (3.5 - world.finish_position.z), 0, 1) * 350
	roll_label.text = "滚动就绪" if player.roll_cooldown <= 0 else "冷却 %.1f 秒" % player.roll_cooldown
	item_label.text = CourseData.ITEMS[player.held_item].name if player.held_item >= 0 else "等待拾取"
	var effect_names := {"speed": "汽水加速", "shield": "泡泡护盾", "jump": "弹簧鞋", "magnet": "星星磁铁", "feather": "轻盈羽毛"}
	var active_effects: PackedStringArray = []
	for effect in player.effects:
		if player.effects[effect] > 0:
			active_effects.append("%s %.0fs" % [effect_names[effect], ceilf(player.effects[effect])])
	effects_label.text = "  ·  ".join(active_effects)

func on_collected(kind: String, item: int) -> void:
	sound.play("star" if kind == "star" else "item")
	if kind == "item":
		toast("拾取「%s」 · 按 E 使用" % CourseData.ITEMS[item].name)

func on_checkpoint(number: int) -> void:
	sound.play("check")
	checkpoint_label.text = "已到达复活点 %d / %d" % [number, world.checkpoints.size()]
	toast("复活点已点亮，放心向前！")

func on_fall() -> void:
	sound.play("fall")
	toast("再来一次！已返回最近的复活点")

func on_item_used(item: int) -> void:
	sound.play("item")
	toast("%s：%s" % [CourseData.ITEMS[item].name, CourseData.ITEMS[item].desc])

var paused_from: String = "racing"

func pause_game() -> void:
	if state != "racing" and state != "countdown": return
	paused_from = state
	state = "paused"
	player.control_enabled = false
	open_modal(Vector2(570, 422))
	text_label(modal, "休息一下", Rect2(36, 36, 498, 59), 40, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	text_label(modal, "计时和机关都已暂停", Rect2(36, 107, 498, 30), 18, MUTED, false, HORIZONTAL_ALIGNMENT_CENTER)
	button(modal, "继续冒险", Rect2(50, 171, 470, 61), resume_game, CORAL, Color.WHITE, 23)
	button(modal, "重新开始", Rect2(50, 248, 226, 58), start_race, Color("e9eeeb"), INK, 19)
	button(modal, "返回大厅", Rect2(293, 248, 226, 58), show_lobby, Color("e9eeeb"), INK, 19)
	text_label(modal, "Esc 继续  ·  F11 全屏", Rect2(50, 347, 470, 27), 15, MUTED, false, HORIZONTAL_ALIGNMENT_CENTER)

func resume_game() -> void:
	if state != "paused": return
	close_modal()
	state = paused_from
	player.control_enabled = state == "racing"

func finish_race() -> void:
	if state != "racing": return
	state = "finished"
	player.control_enabled = false
	world.active = false
	player.visual.visible = true
	sound.play("win")
	var best := float(save.get_value("records", str(selected_map), 0.0))
	var new_record: bool = best <= 0 or race_time < best
	if new_record and persist_records:
		save.set_value("records", str(selected_map), race_time)
		save.save(SAVE_PATH)
	open_modal(Vector2(690, 570))
	text_label(modal, "★   ★   ★", Rect2(45, 30, 600, 59), 47, Color("e8b751"), true, HORIZONTAL_ALIGNMENT_CENTER)
	text_label(modal, "漂亮，成功抵达！", Rect2(45, 108, 600, 66), 41, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	text_label(modal, "新纪录！" if new_record else CourseData.MAPS[selected_map].name + " · 挑战完成", Rect2(45, 184, 600, 34), 19, CORAL, true, HORIZONTAL_ALIGNMENT_CENTER)
	var stats := [format_time(race_time), str(player.stars) + " / " + str(world.stars_total), str(player.falls)]
	var labels := ["本次用时", "收集星星", "复活次数"]
	for i in range(3):
		text_label(modal, stats[i], Rect2(37 + i * 211, 264, 200, 46), 33, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		text_label(modal, labels[i], Rect2(37 + i * 211, 323, 200, 26), 16, MUTED, false, HORIZONTAL_ALIGNMENT_CENTER)
	button(modal, "下一张地图   →", Rect2(47, 398, 596, 65), next_map, CORAL, Color.WHITE, 23)
	button(modal, "再挑战一次", Rect2(47, 482, 286, 49), start_race, Color("e9eeeb"), INK, 17)
	button(modal, "返回大厅", Rect2(350, 482, 293, 49), show_lobby, Color("e9eeeb"), INK, 17)
	confetti.clear()
	for i in range(70):
		var bit := ColorRect.new()
		bit.color = [CORAL, Color("f5cd66"), Color("84caba"), Color("b6a4d9")][i % 4]
		bit.position = Vector2(randf_range(0, 1440), randf_range(-260, -10))
		bit.size = Vector2(randf_range(6, 12), randf_range(11, 20))
		bit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(bit)
		confetti.append({"node": bit, "velocity": Vector2(randf_range(-70, 70), randf_range(60, 130)), "spin": randf_range(-4, 4)})

func next_map() -> void:
	selected_map = (selected_map + 1) % CourseData.MAPS.size()
	start_race()

func show_help() -> void:
	open_modal(Vector2(750, 620))
	text_label(modal, "准备好，滚起来！", Rect2(38, 32, 670, 63), 36, INK, true)
	text_label(modal, "越过平台和机关，到达金色终点环即可完成挑战。", Rect2(40, 110, 670, 31), 19, MUTED)
	var rows := [
		["WASD / 方向键", "移动，空中也能调整方向"],
		["空格", "跳跃，踩青色弹床可自动弹得更高"],
		["Shift", "滚动冲刺，冷却 3.2 秒"],
		["E", "使用拾取的道具，同时可携带 1 个"],
		["R", "返回最近复活点，星星和道具保留"],
		["Esc / F11", "暂停 / 切换全屏"]
	]
	for i in range(rows.size()):
		panel(modal, Rect2(38, 171 + i * 49, 674, 44), Color("f0f2eb") if i % 2 == 0 else PAPER, 9)
		text_label(modal, rows[i][0], Rect2(52, 180 + i * 49, 198, 25), 17, INK, true)
		text_label(modal, rows[i][1], Rect2(256, 180 + i * 49, 442, 25), 17, MUTED)
	text_label(modal, "绿色小旗是复活点 · 金色星星是额外挑战 · 最佳用时自动保存", Rect2(38, 490, 680, 27), 16, Color("679b84"))
	button(modal, "知道了，出发！", Rect2(39, 541, 672, 51), close_modal, CORAL, Color.WHITE, 20)

func show_guide() -> void:
	open_modal(Vector2(880, 663))
	text_label(modal, "把快乐装进口袋", Rect2(39, 29, 750, 66), 37, INK, true)
	text_label(modal, "碰到彩色道具盒即可拾取，按 E 释放。道具效果可以叠加。", Rect2(41, 109, 797, 30), 18, MUTED)
	for i in range(6):
		var item: Dictionary = CourseData.ITEMS[i]
		var x := 40 + (i % 2) * 407
		var y := 168 + (i / 2) * 131
		panel(modal, Rect2(x, y, 390, 115), Color("f0f2ed"), 16)
		panel(modal, Rect2(x + 14, y + 17, 57, 57), Color(item.color), 17)
		text_label(modal, item.symbol, Rect2(x + 14, y + 24, 57, 40), 28, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
		text_label(modal, item.name, Rect2(x + 85, y + 14, 290, 29), 21, INK, true)
		var description := text_label(modal, item.desc, Rect2(x + 85, y + 52, 287, 58), 16, MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(modal, "准备好了", Rect2(40, 582, 800, 52), close_modal, CORAL, Color.WHITE, 21)

func open_modal(modal_size: Vector2) -> void:
	close_modal()
	var veil := ColorRect.new()
	veil.name = "ModalVeil"
	veil.color = Color(0.12, 0.20, 0.27, 0.49)
	veil.size = Vector2(1440, 900)
	ui.add_child(veil)
	modal = panel(veil, Rect2((Vector2(1440, 900) - modal_size) / 2, modal_size), PAPER, 30)
	var accent := Panel.new()
	accent.position = Vector2(32, 17)
	accent.size = Vector2(modal_size.x - 64, 4)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent.add_theme_stylebox_override("panel", rounded(CORAL, 2))
	modal.add_child(accent)
	text_label(modal, "GOGO / STUDIO", Rect2(35, 24, 190, 18), 10, Color("a3a9a4"), true)
	sound.play("click")

func close_modal() -> void:
	var veil := ui.get_node_or_null("ModalVeil")
	if veil != null:
		ui.remove_child(veil)
		veil.queue_free()
	modal = null

func create_toast() -> void:
	toast_label = text_label(ui, "", Rect2(290, 139, 860, 49), 20, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	toast_label.add_theme_stylebox_override("normal", rounded(Color(1, 0.99, 0.95, 0.94), 16))
	toast_label.modulate.a = 0

func toast(message: String, duration: float = 3.0) -> void:
	if is_instance_valid(toast_label):
		toast_label.text = message
		toast_left = duration
		toast_label.modulate.a = 1

func rounded(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = Color(0.14, 0.22, 0.27, 0.10)
	style.set_border_width_all(1)
	style.shadow_color = Color(0.07, 0.15, 0.21, 0.14)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style

func panel(parent: Node, rect: Rect2, color: Color, radius: int) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_stylebox_override("panel", rounded(color, radius))
	parent.add_child(node)
	return node

func text_label(parent: Node, value: String, rect: Rect2, size_px: int = 20, color: Color = INK, heavy: bool = false, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var node := Label.new()
	node.text = value
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_override("font", bold if heavy else font)
	node.add_theme_font_size_override("font_size", size_px)
	node.add_theme_color_override("font_color", color)
	node.horizontal_alignment = alignment
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func button(parent: Node, value: String, rect: Rect2, callback: Callable, color: Color = CORAL, text_color: Color = Color.WHITE, size_px: int = 21) -> Button:
	var node := Button.new()
	node.text = value
	node.position = rect.position
	node.size = rect.size
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_override("font", bold)
	node.add_theme_font_size_override("font_size", size_px)
	node.add_theme_color_override("font_color", text_color)
	node.add_theme_color_override("font_hover_color", text_color)
	node.add_theme_color_override("font_pressed_color", text_color)
	node.add_theme_stylebox_override("normal", rounded(color, 17))
	node.add_theme_stylebox_override("hover", rounded(color.lightened(0.10), 17))
	node.add_theme_stylebox_override("pressed", rounded(color.darkened(0.08), 17))
	var focus := rounded(Color(1, 1, 1, 0), 17)
	focus.border_color = INK
	focus.set_border_width_all(2)
	node.add_theme_stylebox_override("focus", focus)
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

func format_time(seconds: float) -> String:
	return "%02d:%02d.%02d" % [int(seconds) / 60, int(seconds) % 60, int(seconds * 100) % 100]

func capture_screens() -> void:
	persist_records = false
	await get_tree().create_timer(2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_dir.path_join("lobby.png"))
	show_guide()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_dir.path_join("items.png"))
	close_modal()
	for i in range(CourseData.MAPS.size()):
		selected_map = i
		start_race()
		await get_tree().create_timer(0.4).timeout
		count_label.hide()
		player.position = world.platforms[1].position + Vector3(0, 0.3, 5)
		camera.position = player.position + Vector3(0, 9, 14)
		camera.look_at(player.position + Vector3(0, 1, -6))
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(capture_dir.path_join("map_%d.png" % i))
	state = "racing"
	race_time = 42.56
	player.stars = 12
	player.falls = 2
	finish_race()
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_dir.path_join("results.png"))
	print("CAPTURE COMPLETE")
	get_tree().quit()
