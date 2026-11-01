class_name PartyRunner
extends CharacterBody3D

signal collected(kind: String, item: int)
signal checkpoint_reached(number: int)
signal fell
signal finished
signal bounced
signal jumped
signal item_used(item: int)

var visual: Node3D
var shield_visual: Node3D
var checkpoint := Vector3(0, 0.25, 3.5)
var control_enabled: bool = false
var gravity: float = 22.0
var icy: bool = false
var held_item: int = -1
var effects: Dictionary = {}
var stars: int = 0
var falls: int = 0
var roll_left: float = 0.0
var roll_cooldown: float = 0.0
var hit_cooldown: float = 0.0
var knockback_left: float = 0.0
var coyote: float = 0.0
var jump_buffer: float = 0.0
var time: float = 0.0
var motion_input := Vector2.ZERO
var roll_direction := Vector3.FORWARD

func _ready() -> void:
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.49
	capsule.height = 1.42
	collider.shape = capsule
	collider.position.y = 0.74
	add_child(collider)
	floor_snap_length = 0.28
	floor_max_angle = deg_to_rad(48)
	set_skin(0)
	var shield_color := Color("9bdef8")
	shield_color.a = 0.22
	shield_visual = ToyFactory.ball(self, Vector3(0, 0.8, 0), Vector3.ONE * 2.1, shield_color)
	shield_visual.hide()

func set_skin(index: int) -> void:
	if is_instance_valid(visual):
		remove_child(visual)
		visual.queue_free()
	visual = ToyFactory.egg(self, CourseData.SKINS[index], index)

func reset(at: Vector3, map_data: Dictionary) -> void:
	position = at
	checkpoint = at
	velocity = Vector3.ZERO
	gravity = map_data.gravity
	icy = map_data.ice
	held_item = -1
	effects.clear()
	stars = 0
	falls = 0
	roll_left = 0
	roll_cooldown = 0
	hit_cooldown = 0
	knockback_left = 0
	visual.rotation = Vector3.ZERO
	visual.scale = Vector3.ONE
	shield_visual.hide()

func _physics_process(delta: float) -> void:
	time += delta
	if not control_enabled:
		return
	for effect in effects.keys():
		effects[effect] = maxf(0, effects[effect] - delta)
	roll_left = maxf(0, roll_left - delta)
	roll_cooldown = maxf(0, roll_cooldown - delta)
	hit_cooldown = maxf(0, hit_cooldown - delta)
	knockback_left = maxf(0, knockback_left - delta)
	shield_visual.visible = effects.get("shield", 0.0) > 0
	visual.visible = hit_cooldown < 0.1 or int(time * 15) % 2 == 0
	motion_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(motion_input.x, 0, motion_input.y)
	var grounded := is_on_floor()
	coyote = 0.13 if grounded else maxf(0, coyote - delta)
	jump_buffer = 0.14 if Input.is_action_just_pressed("jump") else maxf(0, jump_buffer - delta)
	if Input.is_action_just_pressed("roll") and roll_cooldown <= 0:
		roll_left = 0.85
		roll_cooldown = 3.2
		roll_direction = direction.normalized() if direction.length() > 0.1 else Vector3.FORWARD
	if Input.is_action_just_pressed("use_item"):
		use_item()
	if Input.is_action_just_pressed("respawn"):
		respawn()
		return
	var speed: float = 8.4 * (1.65 if effects.get("speed", 0.0) > 0 else 1.0)
	if roll_left > 0:
		speed = 14.5
		direction = roll_direction.lerp(direction, 0.20) if direction.length() > 0.1 else roll_direction
	var acceleration: float = 5.0 if icy and grounded else (23.0 if grounded else 13.0)
	if knockback_left <= 0:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	var g := gravity
	if effects.get("feather", 0.0) > 0 and velocity.y < 0 and Input.is_action_pressed("jump"):
		g *= 0.15
		velocity.y = maxf(velocity.y, -2.7)
	if not grounded:
		velocity.y -= g * delta
	if jump_buffer > 0 and coyote > 0:
		velocity.y = 10.6 * (1.4 if effects.get("jump", 0.0) > 0 else 1.0)
		coyote = 0
		jump_buffer = 0
		jumped.emit()
	move_and_slide()
	if position.y < -12:
		respawn()
		return
	if direction.length() > 0.08:
		var target_angle := atan2(direction.x, direction.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, delta * 12)
	if roll_left > 0:
		visual.rotation.x += delta * 17
		visual.scale = visual.scale.lerp(Vector3(1.12, 0.82, 1.12), delta * 12)
	else:
		visual.rotation.x = lerp_angle(visual.rotation.x, 0, delta * 15)
		visual.scale = visual.scale.lerp(Vector3.ONE, delta * 12)
	visual.position.y = absf(sin(time * 15)) * 0.055 if grounded and direction.length() > 0.1 else 0.0
	visual.rotation.z = sin(time * 14) * 0.06 * direction.length()

func collect(kind: String, item: int) -> void:
	if kind == "star":
		stars += 1
	else:
		held_item = item
	collected.emit(kind, item)

func use_item() -> void:
	if held_item < 0:
		return
	var item := held_item
	held_item = -1
	match item:
		0: effects["speed"] = 6.0
		1: effects["shield"] = 8.0
		2: effects["jump"] = 8.0
		3: effects["magnet"] = 8.0
		4: effects["feather"] = 6.0
		5: respawn(false)
	item_used.emit(item)

func hit(impulse: Vector3) -> void:
	if effects.get("shield", 0.0) > 0 or hit_cooldown > 0:
		return
	velocity = impulse
	hit_cooldown = 1.25
	knockback_left = 0.32
	roll_left = 0

func respawn(count_fall: bool = true) -> void:
	position = checkpoint + Vector3.UP * 0.5
	velocity = Vector3.ZERO
	roll_left = 0
	knockback_left = 0
	hit_cooldown = 1.6
	if count_fall:
		falls += 1
		fell.emit()
