extends SceneTree

var game: Node3D
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		print("FAIL: ", label)

func frames(count: int) -> void:
	for i in range(count): await physics_frame

func click(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	root.push_input(motion)
	var event := InputEventMouseButton.new()
	event.position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)
	await frames(2)

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func run() -> void:
	root.size = Vector2i(1440, 900)
	game = load("res://scenes/main.tscn").instantiate()
	game.persist_records = false
	root.add_child(game)
	await frames(3)
	for i in range(6):
		await click(Vector2(145 + 224 * i, 687))
		check(game.selected_map == i and game.world.map_index == i, "Map button %d changes course" % i)
	await click(Vector2(283, 820))
	check(game.selected_skin == 2, "Skin swatch changes character")
	await click(Vector2(1130, 58))
	check(is_instance_valid(game.modal), "Guide button opens modal")
	key(KEY_ESCAPE, true)
	await frames(1)
	key(KEY_ESCAPE, false)
	check(not is_instance_valid(game.modal), "Escape dismisses guide")
	await click(Vector2(946, 827))
	check(is_instance_valid(game.modal), "Help button opens modal")
	await click(Vector2(721, 707))
	check(not is_instance_valid(game.modal), "Help confirmation closes modal")
	await click(Vector2(1218, 827))
	check(game.state == "countdown", "Start button starts countdown")
	await frames(240)
	check(game.state == "racing" and game.player.control_enabled, "Countdown unlocks control")
	var z_before: float = game.player.position.z
	key(KEY_W, true)
	await frames(40)
	key(KEY_W, false)
	check(game.player.position.z < z_before - 2, "Physical W key moves runner")
	key(KEY_SPACE, true)
	await frames(8)
	key(KEY_SPACE, false)
	check(game.player.position.y > 0.6, "Physical space key jumps")
	key(KEY_SHIFT, true)
	await frames(2)
	key(KEY_SHIFT, false)
	check(game.player.roll_left > 0, "Physical Shift key rolls")
	key(KEY_ESCAPE, true)
	await frames(2)
	key(KEY_ESCAPE, false)
	check(game.state == "paused", "Escape pauses race")
	await click(Vector2(717, 440))
	check(game.state == "racing", "Continue button resumes")
	key(KEY_R, true)
	await frames(2)
	key(KEY_R, false)
	check(game.player.position.distance_to(game.player.checkpoint) < 2, "Physical R key recalls")
	game.player.held_item = 0
	key(KEY_E, true)
	await frames(2)
	key(KEY_E, false)
	check(game.player.effects.get("speed", 0) > 0, "Physical E key uses held item")
	game.pause_game()
	await frames(1)
	await click(Vector2(593, 514))
	check(game.state == "countdown" and game.race_time == 0, "Restart button resets race")
	game.pause_game()
	await frames(1)
	await click(Vector2(846, 514))
	check(game.state == "lobby", "Lobby button returns to map selection")
	# Check map mechanisms with real scene geometry and the same interactions as gameplay.
	for map_index in range(6):
		game.selected_map = map_index
		game.start_race()
		game.state = "test"
		var course: PartyCourse = game.world
		var runner: PartyRunner = game.player
		for hazard in course.hazards:
			runner.velocity = Vector3.ZERO
			runner.hit_cooldown = 0
			runner.effects.clear()
			runner.position = hazard.center
			match hazard.kind:
				"sweeper":
					course.tick(0.2)
					check(absf(hazard.node.rotation.y) > 0, "Sweeper rotates")
					course.interact(runner, 0.016)
					check(runner.hit_cooldown > 0, "Sweeper collides")
				"bumper":
					runner.position = hazard.center + Vector3(0.5, -0.6, 0)
					course.interact(runner, 0.016)
					check(runner.velocity.length() > 0, "Bumper bounces runner")
				"fire":
					hazard.node.visible = true
					course.interact(runner, 0.016)
					check(runner.hit_cooldown > 0, "Active flame collides")
				"bounce":
					course.interact(runner, 0.016)
					check(runner.velocity.y == 14, "Spring pad launches runner")
				"wind":
					course.interact(runner, 0.2)
					check(runner.velocity.x > 0, "Wind changes lateral velocity")
				"gate":
					runner.position = hazard.node.global_position - Vector3(0, 0.8, 0)
					course.interact(runner, 0.016)
					check(runner.hit_cooldown > 0, "Moving gate collides")
				"pendulum":
					runner.position = hazard.node.to_global(Vector3(0, -4.7, 0)) - Vector3.UP * 0.5
					course.interact(runner, 0.016)
					check(runner.hit_cooldown > 0, "Pendulum collides")
		for platform in course.platforms:
			if platform.kind == "moving":
				var before: float = platform.body.position.x
				course.tick(0.4)
				check(absf(platform.body.position.x - before) > 0.01, "Moving platform changes position")
			if platform.kind == "crumble":
				course.elapsed = 4.5 - platform.phase
				course.tick(0.0)
				check(platform.body.collision_layer == 0 and not platform.body.visible, "Crumble platform disables collision")
				course.elapsed = 5.5 - platform.phase
				course.tick(0.0)
				check(platform.body.collision_layer == 1 and platform.body.visible, "Crumble platform restores collision")
		# Test finish through the real position trigger.
		game.state = "racing"
		game.race_time = 30
		runner.position = course.finish_position
		course.interact(runner, 0.016)
		check(game.state == "finished", "Map %d finish gate completes race" % map_index)
		await frames(2)
	print("INTERACTION RESULT: %d checks, %d failures" % [checks, failures.size()])
	for message in failures: print(message)
	root.remove_child(game)
	game.queue_free()
	await frames(3)
	ToyFactory.materials.clear()
	quit(0 if failures.is_empty() else 1)
