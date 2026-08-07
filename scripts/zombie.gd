extends CharacterBody3D

signal died
var target: Node3D
var health := 100
var attack_delay := 0.0

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	shape.shape = capsule
	add_child(shape)
	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.4
	mesh.height = 1.8
	body.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("4b5144")
	material.roughness = 1.0
	body.material_override = material
	add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.32
	sphere.height = 0.64
	head.mesh = sphere
	head.position.y = 1.1
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color("6b6a58")
	head.material_override = hm
	add_child(head)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target): return
	attack_delay -= delta
	var dist := global_position.distance_to(target.global_position)
	if dist > 1.25:
		var direction := (target.global_position-global_position)
		direction.y = 0
		velocity = direction.normalized()*1.35
		look_at(Vector3(target.global_position.x,global_position.y,target.global_position.z),Vector3.UP)
		move_and_slide()
	elif attack_delay <= 0:
		target.take_damage(18)
		attack_delay = 1.1

func take_damage(amount: int, _hit_position := Vector3.ZERO) -> void:
	health -= amount
	if health <= 0:
		died.emit()
		queue_free()

