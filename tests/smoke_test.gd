extends SceneTree

var game: Node3D
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		print("FAIL: ", description)

func frames(count: int) -> void:
	for i in range(count): await physics_frame

func clear_input() -> void:
	for action in ["move_forward", "move_back", "move_left", "move_right", "jump", "roll", "use_item"]:
		Input.action_release(action)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.persist_records = false
	root.add_child(game)
	await frames(3)
	check(game.state == "lobby", "Game opens in lobby")
	check(game.map_buttons.size() == 6, "All six map buttons appear")
	game.show_guide()
	check(is_instance_valid(game.modal), "Item guide opens")
	game.close_modal()
	game.show_help()
	check(is_instance_valid(game.modal), "Help opens")
	game.close_modal()
	for map_index in range(6):
		game.selected_map = map_index
		game.start_race()
		await frames(3)
		var course: PartyCourse = game.world
		var runner: PartyRunner = game.player
		check(course.platforms.size() >= 7, "Map %d has full course" % map_index)
		check(course.stars_total >= 15, "Map %d has stars" % map_index)
		check(course.checkpoints.size() >= 2, "Map %d has checkpoints" % map_index)
		check(course.pickups.size() >= 20, "Map %d has item pickups" % map_index)
		# Park main's frame controller, retain real CharacterBody3D physics.
		game.state = "test"
		course.active = false
		runner.control_enabled = true
		await frames(20)
		check(runner.is_on_floor(), "Map %d start is grounded" % map_index)
		for segment in range(course.platforms.size() - 1):
			var from: Dictionary = course.platforms[segment]
			var to: Dictionary = course.platforms[segment + 1]
			# Crumble and moving platforms are tested at their stable starting state.
			from.body.collision_layer = 1
			to.body.collision_layer = 1
			from.body.position = from.origin
			to.body.position = to.origin
			clear_input()
			runner.position = from.position + Vector3(0, 0.15, -4.0)
			runner.velocity = Vector3.ZERO
			runner.knockback_left = 0
			runner.roll_left = 0
			await frames(18)
			check(runner.is_on_floor(), "Map %d segment %d takeoff is grounded" % [map_index, segment])
			var edge: float = from.position.z - from.depth / 2
			var target_x: float = to.position.x
			Input.action_press("move_forward")
			var jumped := false
			var landed := false
			var falls_before: int = runner.falls
			for frame in range(200):
				if absf(target_x - runner.position.x) > 0.3:
					Input.action_press("move_right" if target_x > runner.position.x else "move_left", 0.6)
					Input.action_release("move_left" if target_x > runner.position.x else "move_right")
				else:
					Input.action_release("move_left")
					Input.action_release("move_right")
				if not jumped and runner.position.z < edge + 1.3:
					Input.action_press("jump")
					jumped = true
				else: Input.action_release("jump")
				await physics_frame
				if runner.falls != falls_before: break
				if jumped and runner.position.z < to.position.z + 7.1 and runner.is_on_floor():
					landed = true
					break
			clear_input()
			check(landed, "Map %d gap %d is traversable with normal jump" % [map_index, segment])
		# Use interactions, not button text, to verify collectibles and checkpoints.
		runner.control_enabled = false
		var star: Dictionary = course.pickups[0]
		runner.position = star.node.position
		var initial_stars: int = runner.stars
		course.interact(runner, 0.016)
		check(runner.stars == initial_stars + 1, "Map %d star collection" % map_index)
		runner.control_enabled = true
		runner.position = course.checkpoints[0]
		runner.velocity = Vector3.ZERO
		await frames(35)
		course.interact(runner, 0.016)
		check(course.last_checkpoint >= 0, "Map %d checkpoint activates" % map_index)
		var checkpoint: Vector3 = runner.checkpoint
		runner.position.y = -15
		await frames(2)
		check(runner.position.distance_to(checkpoint) < 2, "Map %d fall respawns" % map_index)
		print("MAP %d checked: %s" % [map_index + 1, course.data.name])
	var runner: PartyRunner = game.player
	runner.control_enabled = false
	for item in range(6):
		runner.effects.clear()
		runner.held_item = item
		runner.position = Vector3(30, 8, -50)
		runner.use_item()
		check(runner.held_item == -1, "Item %d consumed" % item)
		if item < 5:
			var effect: String = ["speed", "shield", "jump", "magnet", "feather"][item]
			check(runner.effects.get(effect, 0) > 0, "Item %d applies effect" % item)
		else:
			check(runner.position.distance_to(runner.checkpoint) < 1, "Recall returns to checkpoint")
	runner.effects.clear()
	runner.hit_cooldown = 0
	runner.velocity = Vector3.ZERO
	runner.effects["shield"] = 8.0
	runner.hit(Vector3(10, 5, 0))
	check(runner.velocity == Vector3.ZERO, "Shield prevents knockback")
	runner.effects.clear()
	runner.hit(Vector3(10, 5, 0))
	check(runner.velocity.x == 10, "Hazards apply knockback")
	game.state = "racing"
	game.pause_game()
	check(game.state == "paused" and not runner.control_enabled, "Pause freezes player")
	var frozen_time: float = game.race_time
	var frozen_world: float = game.world.elapsed
	await frames(8)
	check(game.race_time == frozen_time and game.world.elapsed == frozen_world, "Pause freezes timer and obstacles")
	game.resume_game()
	check(game.state == "racing" and runner.control_enabled, "Resume restores gameplay")
	game.race_time = 44.5
	game.finish_race()
	check(game.state == "finished" and is_instance_valid(game.modal), "Finish shows results")
	game.next_map()
	check(game.selected_map == 0 and game.state == "countdown", "Next map wraps from six to one")
	game.show_lobby()
	check(game.state == "lobby" and game.map_buttons.size() == 6, "Return to lobby rebuilds selection")
	print("RESULT: %d checks, %d failures" % [checks, failures.size()])
	for failure in failures: print("  ", failure)
	root.remove_child(game)
	game.queue_free()
	await frames(3)
	ToyFactory.materials.clear()
	quit(0 if failures.is_empty() else 1)
