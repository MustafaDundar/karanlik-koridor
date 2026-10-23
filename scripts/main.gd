extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
var player: CharacterBody3D
var hud: Label
var message_time := 0.0
var door: StaticBody3D
var door_open := false
var scare_triggered := false
var lamps: Array[OmniLight3D] = []

func _ready() -> void:
    _build_environment()
    _build_corridor()
    player = CharacterBody3D.new()
    player.set_script(PlayerScript)
    add_child(player)
    _create_hud()
    _show_message("KARANLIK KORIDOR  |  Cikisi bul.", 5.0)

func _build_environment() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.012, 0.018, 0.025)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.08, 0.10, 0.14)
    env.ambient_light_energy = 0.22
    env.fog_enabled = true
    env.fog_light_color = Color(0.045, 0.06, 0.07)
    env.fog_density = 0.025
    world.environment = env
    add_child(world)

func _make_box(box_name: String, pos: Vector3, size: Vector3, color: Color, collidable: bool = true) -> Node3D:
    var root: Node3D = StaticBody3D.new() if collidable else Node3D.new()
    root.name = box_name
    root.position = pos
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.93
    mesh.material_override = mat
    root.add_child(mesh)
    if collidable:
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        root.add_child(collision)
    add_child(root)
    return root

func _build_corridor() -> void:
    var stone := Color(0.23, 0.25, 0.24)
    var sick_green := Color(0.17, 0.24, 0.20)
    _make_box("Floor", Vector3(0, -0.15, -22), Vector3(5, 0.3, 52), stone)
    _make_box("Ceiling", Vector3(0, 3.5, -22), Vector3(5, 0.3, 52), Color(0.18, 0.19, 0.19))
    for side in [-1, 1]:
        _make_box("Wall", Vector3(side * 2.55, 1.7, -22), Vector3(0.3, 3.6, 52), sick_green)
        for z in range(3, -47, -6):
            _make_box("WallTrim", Vector3(side * 2.36, 0.72, z - 2.0), Vector3(0.10, 1.3, 4.0), Color(0.11, 0.16, 0.14), false)
    for z in range(0, -44, -7):
        _make_box("CeilingFixture", Vector3(0, 3.28, z), Vector3(1.3, 0.08, 0.23), Color(0.75, 0.8, 0.70), false)
        var lamp := OmniLight3D.new()
        lamp.position = Vector3(0, 3.1, z)
        lamp.light_color = Color(0.7, 0.88, 0.76)
        lamp.light_energy = 0.8
        lamp.omni_range = 7
        lamp.shadow_enabled = true
        add_child(lamp)
        lamps.append(lamp)
    door = _make_box("ExitDoor", Vector3(0, 1.5, -47.3), Vector3(2.0, 3.0, 0.25), Color(0.17, 0.19, 0.20)) as StaticBody3D
    _make_box("EndWall", Vector3(0, 1.7, -48.1), Vector3(5.0, 3.6, 0.3), Color(0.16, 0.20, 0.17))
    for z in [-6, -18, -30, -42]:
        _make_box("Bench", Vector3(1.7, 0.43, z), Vector3(0.8, 0.12, 1.6), Color(0.22, 0.16, 0.12))
    _make_box("DoorSign", Vector3(0, 3.1, -47.05), Vector3(1.3, 0.25, 0.06), Color(0.05, 0.32, 0.14), false)

func _create_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    hud = Label.new()
    hud.position = Vector2(24, 24)
    hud.add_theme_font_size_override("font_size", 20)
    hud.add_theme_color_override("font_color", Color(0.85, 0.92, 0.84))
    layer.add_child(hud)
    var crosshair := Label.new()
    crosshair.text = "+"
    crosshair.anchor_left = 0.5
    crosshair.anchor_top = 0.5
    crosshair.anchor_right = 0.5
    crosshair.anchor_bottom = 0.5
    crosshair.offset_left = -5
    crosshair.offset_top = -10
    crosshair.add_theme_font_size_override("font_size", 20)
    layer.add_child(crosshair)

func _process(delta: float) -> void:
    if not is_instance_valid(player):
        return
    var distance := absf(player.position.z + 47.3)
    if player.position.z < -24 and not scare_triggered:
        scare_triggered = true
        _show_message("Birisi seni izliyor...", 4.0)
    if distance < 2.5 and Input.is_action_just_pressed("interact") and not door_open:
        door_open = true
        door.collision_layer = 0
        door.visible = false
        _show_message("Kapi acildi. Ama arkada ne var?", 6.0)
    if door_open and player.position.z < -47.7:
        _show_message("BOLUM 1 TAMAMLANDI", 1.0)
    if message_time > 0:
        message_time -= delta
    elif message_time <= 0:
        hud.text = "PIL: %d%%   |   WASD Hareket   SHIFT Kos   F Fener   E Kapi   ESC Fare" % int(player.get("battery"))
    for i in range(lamps.size()):
        if i == 3 and scare_triggered:
            lamps[i].light_energy = 0.03 if sin(Time.get_ticks_msec() * 0.025) > 0.0 else 0.8

func _show_message(message: String, duration: float) -> void:
    hud.text = message
    message_time = duration
