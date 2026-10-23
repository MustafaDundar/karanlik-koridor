extends CharacterBody3D

# Procedural fallback enemy while Hugging Face 3D export is unavailable.
# All limbs are separate meshes; walking animation is computed at runtime.
var target: Node3D
var speed := 1.55
var active := false
var phase := 0.0
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var head: Node3D

func _ready() -> void:
    name = "CorridorStalker"
    collision_layer = 2
    collision_mask = 1
    var body_collision := CollisionShape3D.new()
    var body_shape := CapsuleShape3D.new()
    body_shape.radius = 0.30
    body_shape.height = 1.85
    body_collision.shape = body_shape
    body_collision.position.y = 0.93
    add_child(body_collision)
    _part("Torso", Vector3(0, 1.28, 0), Vector3(0.58, 0.80, 0.30), Color(0.12, 0.12, 0.13), self)
    head = Node3D.new()
    head.position = Vector3(0, 1.79, 0)
    add_child(head)
    _part("Head", Vector3.ZERO, Vector3(0.36, 0.39, 0.36), Color(0.57, 0.56, 0.48), head)
    for side in [-1.0, 1.0]:
        _part("Eye", Vector3(side * 0.095, 0.035, -0.187), Vector3(0.055, 0.052, 0.02), Color(0.88, 0.07, 0.04), head, true)
    left_arm = _limb("LeftArm", Vector3(-0.39, 1.54, 0), Vector3(0.16, 0.65, 0.16), Color(0.12, 0.12, 0.13))
    right_arm = _limb("RightArm", Vector3(0.39, 1.54, 0), Vector3(0.16, 0.65, 0.16), Color(0.12, 0.12, 0.13))
    left_leg = _limb("LeftLeg", Vector3(-0.17, 0.83, 0), Vector3(0.20, 0.75, 0.21), Color(0.13, 0.13, 0.14))
    right_leg = _limb("RightLeg", Vector3(0.17, 0.83, 0), Vector3(0.20, 0.75, 0.21), Color(0.13, 0.13, 0.14))

func _part(label: String, offset: Vector3, dimensions: Vector3, color: Color, parent: Node3D, emissive: bool = false) -> void:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = label
    mesh_instance.position = offset
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    mesh_instance.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.9
    if emissive:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 3.0
    mesh_instance.material_override = mat
    parent.add_child(mesh_instance)

func _limb(label: String, joint: Vector3, size: Vector3, color: Color) -> Node3D:
    var pivot := Node3D.new()
    pivot.name = label
    pivot.position = joint
    add_child(pivot)
    _part(label + "Mesh", Vector3(0, -size.y * 0.48, 0), size, color, pivot)
    return pivot

func _physics_process(delta: float) -> void:
    if not active or not is_instance_valid(target):
        return
    var diff := target.global_position - global_position
    diff.y = 0.0
    if diff.length() > 1.3:
        var direction := diff.normalized()
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
        phase += delta * 7.5
        left_leg.rotation.x = sin(phase) * 0.48
        right_leg.rotation.x = -sin(phase) * 0.48
        left_arm.rotation.x = -sin(phase) * 0.37
        right_arm.rotation.x = sin(phase) * 0.37
        head.rotation.z = sin(phase * 0.5) * 0.045
    else:
        velocity.x = 0.0
        velocity.z = 0.0
    velocity.y -= 18.0 * delta if not is_on_floor() else 0.0
    move_and_slide()
    if diff.length() > 0.01:
        rotation.y = lerp_angle(rotation.y, atan2(-diff.x, -diff.z), minf(1.0, 4.0 * delta))
