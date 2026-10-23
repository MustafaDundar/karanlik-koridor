extends CharacterBody3D

const WALK_SPEED := 3.4
const RUN_SPEED := 5.7
const MOUSE_SENS := 0.002
const GRAVITY := 18.0

var camera: Camera3D
var light: SpotLight3D
var battery := 100.0
var is_flashlight_on := true
var controls_enabled := true
var stride := 0.0

func _ready() -> void:
    name = "Player"
    position = Vector3(0, 1.1, 3)
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.32
    capsule.height = 1.8
    var collider := CollisionShape3D.new()
    collider.shape = capsule
    add_child(collider)
    camera = Camera3D.new()
    camera.position.y = 0.55
    camera.current = true
    add_child(camera)
    light = SpotLight3D.new()
    light.position = Vector3(0.16, -0.12, -0.15)
    light.light_energy = 2.4
    light.spot_range = 19.0
    light.spot_angle = 37.0
    light.shadow_enabled = true
    camera.add_child(light)
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if not controls_enabled:
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * MOUSE_SENS)
        camera.rotate_x(-event.relative.y * MOUSE_SENS)
        camera.rotation.x = clampf(camera.rotation.x, -1.4, 1.4)
    if event.is_action_pressed("flashlight"):
        is_flashlight_on = not is_flashlight_on
    if event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventMouseButton and event.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
    if not controls_enabled or (Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and DisplayServer.get_name() != "headless"):
        velocity = Vector3.ZERO
        return
    var motion := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var speed := RUN_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
    var direction := (transform.basis * Vector3(motion.x, 0, motion.y)).normalized()
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    else:
        velocity.y = 0.0
    move_and_slide()
    if motion.length() > 0.1 and is_on_floor():
        stride += delta * speed * 2.4
    camera.position.y = lerpf(camera.position.y, 0.55 + sin(stride) * 0.025 * motion.length(), minf(1.0, delta * 12.0))
    if is_flashlight_on and battery > 0.0:
        battery = maxf(0.0, battery - delta * 0.65)
    light.visible = is_flashlight_on and battery > 0.0
