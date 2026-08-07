extends CharacterBody3D

signal health_changed(value)
signal ammo_changed(value)
signal interacted(target)
signal died

var speed := 4.2
var health := 100
var ammo := 0
var armed := false
var can_move := true
var camera: Camera3D
var touch_pad: Control
var look_pad: Control
var move_vector := Vector2.ZERO
var look_vector := Vector2.ZERO
var move_touch := -1
var look_touch := -1

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.75
	shape.shape = capsule
	add_child(shape)
	camera = Camera3D.new()
	camera.position.y = 0.68
	camera.current = true
	add_child(camera)
	var light := SpotLight3D.new()
	light.position = Vector3(0,0,-0.1)
	light.rotation_degrees.x = -4
	light.light_color = Color("d9e5ed")
	light.light_energy = 1.6
	light.spot_range = 15
	light.spot_angle = 32
	camera.add_child(light)

func _physics_process(delta: float) -> void:
	if not can_move: return
	var input := Input.get_vector("move_left","move_right","move_forward","move_back")
	if move_touch >= 0:
		input = move_vector
	var dir := (transform.basis * Vector3(input.x,0,input.y)).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if not is_on_floor(): velocity.y -= 18.0 * delta
	move_and_slide()
	if Input.is_action_just_pressed("fire"): shoot()
	if Input.is_action_just_pressed("interact"): try_interact()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look(event.relative)
	if event is InputEventScreenTouch:
		var on_move_pad := _is_on_pad(event.position, touch_pad)
		var on_look_pad := _is_on_pad(event.position, look_pad)
		if event.pressed and on_move_pad and move_touch < 0:
			move_touch = event.index
			_update_joystick(event.position, touch_pad, true)
		elif event.pressed and on_look_pad and look_touch < 0:
			look_touch = event.index
			_update_joystick(event.position, look_pad, false)
		elif not event.pressed and event.index == move_touch:
			move_touch = -1
			move_vector = Vector2.ZERO
			touch_pad.call("reset")
		elif not event.pressed and event.index == look_touch:
			look_touch = -1
			look_vector = Vector2.ZERO
			look_pad.call("reset")
	if event is InputEventScreenDrag:
		if event.index == move_touch:
			_update_joystick(event.position, touch_pad, true)
		elif event.index == look_touch:
			_update_joystick(event.position, look_pad, false)
			look(event.relative)

func _update_joystick(screen_position: Vector2, pad: Control, movement: bool) -> void:
	var center := pad.get_global_rect().get_center()
	var radius: float = minf(pad.size.x, pad.size.y) * 0.46
	var value := ((screen_position - center) / radius).limit_length(1.0)
	pad.call("set_value", value)
	if movement:
		move_vector = value
	else:
		look_vector = value

func _is_on_pad(screen_position: Vector2, pad: Control) -> bool:
	if pad == null:
		return false
	var center := pad.get_global_rect().get_center()
	var radius: float = minf(pad.size.x, pad.size.y) * 0.5
	return screen_position.distance_to(center) <= radius

func look(delta: Vector2) -> void:
	rotate_y(-delta.x * 0.003)
	camera.rotation.x = clamp(camera.rotation.x-delta.y*0.003,-1.25,1.25)

func arm_player() -> void:
	armed = true
	ammo = 12
	ammo_changed.emit(ammo)

func shoot() -> void:
	if not can_move or not armed or ammo <= 0: return
	ammo -= 1
	ammo_changed.emit(ammo)
	var from := camera.global_position
	var to := from + -camera.global_transform.basis.z * 40.0
	var query := PhysicsRayQueryParameters3D.create(from,to)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit and hit.collider.has_method("take_damage"):
		hit.collider.take_damage(55,hit.position)

func try_interact() -> void:
	var from := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from,from-camera.global_transform.basis.z*3.0)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		var target_node: Node = hit.collider
		# Static interaction colliders live directly below the named mesh.
		if target_node is StaticBody3D and target_node.get_parent():
			target_node = target_node.get_parent()
		interacted.emit(target_node)

func take_damage(amount: int) -> void:
	health = max(0,health-amount)
	health_changed.emit(health)
	if health == 0: died.emit()
