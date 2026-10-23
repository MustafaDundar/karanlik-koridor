extends Node3D
# Development inspection scene. The candidate has no generated PBR maps yet.
var angle := 0.45
var camera: Camera3D

func _ready() -> void:
    var model = preload("res://production/review/cabinet-hunyuan-candidate.glb").instantiate()
    add_child(model)
    model.position.y = 0.85
    _material(model)
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color(0.05, 0.065, 0.07)
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color(0.6, 0.7, 0.72)
    environment.environment.ambient_light_energy = 0.55
    add_child(environment)
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-42, -35, 0)
    key.light_energy = 1.3
    key.shadow_enabled = true
    add_child(key)
    camera = Camera3D.new()
    camera.current = true
    camera.fov = 42
    add_child(camera)
    var layer := CanvasLayer.new()
    add_child(layer)
    var label := Label.new()
    label.text = "HUNYUAN 3D 2.1 • 20.000 üçgen\nİNCELEME ADAYI — PBR / UV / oyun içi görsel QA bekliyor\nMalzeme: elle ayarlanmış mint metal; üretilmiş PBR değildir."
    label.position = Vector2(24, 24)
    layer.add_child(label)
    _process(0.0)

func _material(node: Node) -> void:
    if node is MeshInstance3D:
        var material := StandardMaterial3D.new()
        material.albedo_color = Color(0.42, 0.58, 0.51)
        material.roughness = 0.76
        node.material_override = material
    for child in node.get_children():
        _material(child)

func _process(delta: float) -> void:
    angle += delta * 0.2
    camera.position = Vector3(sin(angle) * 4.2, 2.1, cos(angle) * 4.2)
    camera.look_at(Vector3(0, 0.85, 0), Vector3.UP)
