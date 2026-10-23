extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const StalkerScript = preload("res://scripts/stalker.gd")
var player: CharacterBody3D
var hud: Label
var message_time := 0.0
var door: StaticBody3D
var door_open := false
var scare_triggered := false
var lamps: Array[OmniLight3D] = []
var stalker: CharacterBody3D
var fuse: Node3D
var fuse_collected := false
var completed := false
var prompt: Label
var status: Label
var announcement: AudioStreamPlayer3D
var announcement_played := false

func _ready() -> void:
    _build_environment()
    _build_corridor()
    _dress_corridor()
    player = CharacterBody3D.new()
    player.set_script(PlayerScript)
    add_child(player)
    _create_hud()
    announcement = AudioStreamPlayer3D.new()
    announcement.name = "EmergencyPA"
    announcement.position = Vector3(0, 2.8, -5)
    announcement.stream = preload("res://assets/hf/emergency-tr.wav")
    announcement.volume_db = -5.0
    announcement.unit_size = 6.0
    announcement.max_distance = 30.0
    add_child(announcement)
    stalker = CharacterBody3D.new()
    stalker.set_script(StalkerScript)
    stalker.position = Vector3(0, 0, 1)
    stalker.set("target", player)
    add_child(stalker)
    _show_message("KARANLIK KORİDOR  |  Acil çıkışın sigortasını bul.", 5.0)

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
    if box_name in ["Wall", "Floor", "Ceiling", "DoorFrameL", "DoorFrameR", "StartWall", "EndWall"]:
        var aged := ShaderMaterial.new()
        aged.shader = preload("res://shaders/aged_surface.gdshader")
        aged.set_shader_parameter("base_color", color)
        aged.set_shader_parameter("floor_surface", box_name == "Floor")
        mesh.material_override = aged
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
    _make_box("DoorFrameL", Vector3(-1.75, 1.7, -47.3), Vector3(1.5, 3.6, 0.3), sick_green)
    _make_box("DoorFrameR", Vector3(1.75, 1.7, -47.3), Vector3(1.5, 3.6, 0.3), sick_green)
    _make_box("StartWall", Vector3(0, 1.7, 4), Vector3(5, 3.6, 0.3), sick_green)
    fuse = _make_box("Fuse", Vector3(1.7, 0.65, -18), Vector3(0.25, 0.25, 0.25), Color(0.9, 0.55, 0.12), false)
    var marker := OmniLight3D.new()
    marker.light_color = Color(1.0, 0.55, 0.18)
    marker.light_energy = 0.6
    marker.omni_range = 2.5
    fuse.add_child(marker)
    _make_box("EndWall", Vector3(0, 1.7, -50.0), Vector3(5.0, 3.6, 0.3), Color(0.16, 0.20, 0.17))
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
    status = Label.new()
    status.position = Vector2(24, 58)
    status.add_theme_font_size_override("font_size", 17)
    layer.add_child(status)
    prompt = Label.new()
    prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    prompt.position = Vector2(340, 630)
    prompt.size = Vector2(600, 60)
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt.add_theme_font_size_override("font_size", 22)
    layer.add_child(prompt)
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
    announcement.stream_paused = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and DisplayServer.get_name() != "headless" and not completed
    if completed:
        if Input.is_action_just_pressed("restart"):
            get_tree().reload_current_scene()
        return
    if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and DisplayServer.get_name() != "headless":
        status.text = "DURAKLATILDI  |  Devam etmek için tıkla"
        return
    status.text = "PİL %d%%   •   SİGORTA %s" % [int(player.battery), "ALINDI" if fuse_collected else "KAYIP"]
    prompt.text = ""
    if player.position.z < -3 and not announcement_played:
        announcement_played = true
        announcement.play()
        _show_message("ANONS: Acil çıkışın elektriği kesildi. Yedek sigorta bekleme alanında.", announcement.stream.get_length())
    var near_fuse := player.position.distance_to(fuse.position + Vector3(0, 0.8, 0)) < 2.0
    var near_door := player.position.distance_to(Vector3(0, 1, -47.3)) < 2.5
    if near_fuse and not fuse_collected:
        prompt.text = "[E] Acil çıkış sigortasını al"
        if Input.is_action_just_pressed("interact"):
            fuse_collected = true
            fuse.visible = false
            _show_message("Sigorta sende. Acil çıkışa ulaş.", 4.0)
    elif near_door and not door_open:
        prompt.text = "[E] Sigortayı tak ve çıkışı aç" if fuse_collected else "Çıkış kilitli — koridordaki sigortayı bul"
        if Input.is_action_just_pressed("interact") and fuse_collected:
            door_open = true
            door.collision_layer = 0
            door.visible = false
            _show_message("Çıkış açıldı. Arkana bakma.", 4.0)
    if player.position.z < -24 and not scare_triggered:
        scare_triggered = true
        stalker.position = Vector3(0, 0, -12)
        stalker.velocity = Vector3.ZERO
        stalker.active = true
        _show_message("Arkanda ayak sesleri var...", 4.0)
    if scare_triggered and player.global_position.distance_to(stalker.global_position) < 1.5:
        reset_run()
    if door_open and player.position.z < -47.7:
        completed = true
        stalker.active = false
        stalker.velocity = Vector3.ZERO
        player.controls_enabled = false
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        hud.text = "BÖLÜM 1 TAMAMLANDI"
        prompt.text = "[R] Yeniden oyna"
    if message_time > 0:
        message_time -= delta
    elif not completed:
        hud.text = "WASD Hareket   SHIFT Koş   F Fener   E Etkileşim   ESC Duraklat"
    for i in range(lamps.size()):
        lamps[i].light_energy = (0.03 if sin(Time.get_ticks_msec() * 0.025) > 0.0 else 0.8) if i == 3 and scare_triggered else 0.8

func reset_run() -> void:
    announcement.stop()
    announcement_played = false
    player.position = Vector3(0, 1.1, 3)
    player.velocity = Vector3.ZERO
    player.rotation = Vector3.ZERO
    player.camera.rotation = Vector3.ZERO
    player.battery = 100.0
    player.is_flashlight_on = true
    player.controls_enabled = true
    stalker.position = Vector3(0, 0, 1)
    stalker.velocity = Vector3.ZERO
    stalker.active = false
    scare_triggered = false
    door_open = false
    completed = false
    door.collision_layer = 1
    door.visible = true
    fuse_collected = false
    fuse.visible = true
    _show_message("YAKALANDIN! Sigortayı bul ve çıkışa ulaş.", 4.0)

func _show_message(message: String, duration: float) -> void:
    hud.text = message
    message_time = duration

func _dress_corridor() -> void:
    var metal := Color(0.19, 0.23, 0.22)
    for side in [-1, 1]:
        _make_box("Skirting", Vector3(side * 2.36, 0.12, -22), Vector3(0.10, 0.24, 52), metal, false)
        _make_box("Handrail", Vector3(side * 2.28, 1.0, -22), Vector3(0.10, 0.08, 52), metal, false)
        for z in [-8, -20, -32, -44]:
            _make_box("WardDoor", Vector3(side * 2.33, 1.35, z), Vector3(0.10, 2.7, 1.3), Color(0.19, 0.25, 0.24), false)
            _make_box("WardGlass", Vector3(side * 2.26, 1.9, z), Vector3(0.025, 0.48, 0.55), Color(0.025, 0.04, 0.045), false)
            _make_box("WardHandle", Vector3(side * 2.19, 1.15, z + 0.42), Vector3(0.12, 0.06, 0.18), Color(0.48, 0.48, 0.42), false)
    for z in range(0, -44, -7):
        for side in [-1, 1]:
            _make_box("TubeLight", Vector3(side * 0.27, 3.20, z), Vector3(0.06, 0.045, 0.7), Color(0.74, 0.82, 0.72), false)
    var exit_label := Label3D.new()
    exit_label.text = "ACİL ÇIKIŞ ↓"
    exit_label.position = Vector3(0, 3.1, -47.0)
    exit_label.font_size = 46
    exit_label.pixel_size = 0.003
    exit_label.modulate = Color(0.68, 1.0, 0.72)
    exit_label.no_depth_test = false
    add_child(exit_label)
    var notice := Label3D.new()
    notice.text = "SERVİS B  /  03:17\nAcil çıkış gücü kesildi.\nYedek sigorta: bekleme alanı."
    notice.position = Vector3(0, 2.2, 3.78)
    notice.rotation.y = PI
    notice.pixel_size = 0.0025
    notice.font_size = 36
    add_child(notice)
