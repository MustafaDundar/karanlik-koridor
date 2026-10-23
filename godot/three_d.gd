extends Node3D
const GRID = [
"111111111111111",
"100000000000001",
"101110101110101",
"100010100010001",
"100000000000101",
"101011101010101",
"100010001000001",
"101010101011101",
"100000000000001",
"101110101110101",
"100000100000001",
"101010101011101",
"100000000000001",
"111111111111111"
]
var player: CharacterBody3D
var camera: Camera3D
var light: SpotLight3D
var monster: CharacterBody3D
var keys: Array[Node3D] = []
var collected := 0
var battery := 100.0
var ended := false
var touch_dir := Vector2.ZERO
var look_touch := -1
var previous_touch := Vector2.ZERO
var hud: Label
var overlay: ColorRect
var button_positions := {}
var sound: AudioStreamPlayer
var wall_texture: Texture2D
var floor_texture: Texture2D
var monster_texture: Texture2D
var enemy_timer := 0.0

func texture_from_hf(name: String) -> Texture2D:
	var path := "res://assets/" + name + ".webp.b64"
	if not FileAccess.file_exists(path): return null
	var image := Image.new()
	var err := image.load_webp_from_buffer(Marshalls.base64_to_raw(FileAccess.get_file_as_string(path).strip_edges()))
	if err != OK: return null
	return ImageTexture.create_from_image(image)

func material(color: Color, tex: Texture2D = null) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if tex: m.albedo_texture = tex
	m.roughness = 0.93
	return m

func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, collision := false) -> Node3D:
	var node := StaticBody3D.new() if collision else Node3D.new()
	parent.add_child(node)
	node.position = pos
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = mat
	node.add_child(mesh)
	if collision:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		node.add_child(cs)
	return node

func _ready() -> void:
	wall_texture = texture_from_hf("wall")
	floor_texture = texture_from_hf("floor")
	monster_texture = texture_from_hf("monster")
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012,0.018,0.025)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.06,0.085,0.11)
	env.ambient_light_energy = 0.16
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var wall_mat := material(Color(0.54,0.57,0.62),wall_texture)
	var floor_mat := material(Color(0.36,0.36,0.36),floor_texture)
	var ceiling_mat := material(Color(0.12,0.14,0.17))
	for z in range(GRID.size()):
		for x in range(GRID[z].length()):
			if GRID[z][x] == "1":
				box(self,Vector3(x,1.5,z),Vector3(1,3,1),wall_mat,true)
			else:
				box(self,Vector3(x,-0.09,z),Vector3(1,0.18,1),floor_mat,true)
				box(self,Vector3(x,3.06,z),Vector3(1,0.12,1),ceiling_mat)
	player = CharacterBody3D.new()
	add_child(player)
	player.position = Vector3(1.5,0.12,1.5)
	var capsule := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.26
	shape.height = 1.65
	capsule.position.y = 0.88
	capsule.shape = shape
	player.add_child(capsule)
	camera = Camera3D.new()
	camera.position.y = 1.55
	camera.fov = 75
	camera.current = true
	player.add_child(camera)
	light = SpotLight3D.new()
	camera.add_child(light)
	light.position = Vector3(0,-0.08,-0.08)
	light.spot_range = 14
	light.spot_angle = 36
	light.light_energy = 5.5
	light.shadow_enabled = true
	monster = CharacterBody3D.new()
	add_child(monster)
	monster.position = Vector3(12.5,0,12.5)
	var monster_body := Node3D.new()
	monster.add_child(monster_body)
	var dark := material(Color(0.12,0.035,0.045))
	box(monster_body,Vector3(0,1.0,0),Vector3(0.55,1.6,0.3),dark)
	box(monster_body,Vector3(0,2.0,0),Vector3(0.44,0.52,0.36),material(Color(0.67,0.61,0.58)))
	for side in [-1.0,1.0]:
		box(monster_body,Vector3(side*0.4,1.05,0),Vector3(0.15,1.45,0.15),dark)
		box(monster_body,Vector3(side*0.16,0.3,0),Vector3(0.18,0.65,0.2),dark)
		box(monster_body,Vector3(side*0.11,2.06,-0.19),Vector3(0.09,0.05,0.06),material(Color(1,0.02,0.01)))
	for p in [Vector3(13.5,0.65,1.5),Vector3(1.5,0.65,12.5),Vector3(7.5,0.65,8.5)]:
		var k := Node3D.new()
		add_child(k)
		k.position = p
		box(k,Vector3.ZERO,Vector3(0.16,0.25,0.16),material(Color(1,0.68,0.07)))
		var glow := OmniLight3D.new()
		glow.light_color = Color(1,0.7,0.15)
		glow.light_energy = 0.6
		glow.omni_range = 2
		k.add_child(glow)
		keys.append(k)
	var exit_node := Node3D.new()
	add_child(exit_node)
	exit_node.position = Vector3(13.5,1.2,12.5)
	box(exit_node,Vector3.ZERO,Vector3(0.7,2.3,0.13),material(Color(0.1,0.6,0.32)))
	var exit_light := OmniLight3D.new()
	exit_light.light_color = Color(0.1,1,0.45)
	exit_light.light_energy = 1.4
	exit_light.omni_range = 3
	exit_node.add_child(exit_light)
	make_ui()
	sound = AudioStreamPlayer.new()
	add_child(sound)

func make_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Label.new()
	hud.position = Vector2(18,18)
	hud.add_theme_font_size_override("font_size",23)
	canvas.add_child(hud)
	var help := Label.new()
	help.text = "WASD hareket  |  Fare bakis  |  F fener  |  Shift kos"
	help.position = Vector2(18,52)
	canvas.add_child(help)
	overlay = ColorRect.new()
	overlay.color = Color(0.6,0,0,0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(overlay)
	for i in range(5):
		var b := Button.new()
		b.text = ["◀","▲","▼","▶","F"][i]
		b.position = Vector2(16+i*80,440)
		b.size = Vector2(72,72)
		canvas.add_child(b)
		if i == 4:
			b.pressed.connect(func(): light.visible = not light.visible)
		else:
			var d: Vector2 = [Vector2(-1,0),Vector2(0,-1),Vector2(0,1),Vector2(1,0)][i]
			b.button_down.connect(func(): touch_dir = d)
			b.button_up.connect(func(): touch_dir = Vector2.ZERO)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F: light.visible = not light.visible
		if event.keycode == KEY_R and ended: get_tree().reload_current_scene()
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		player.rotate_y(-event.relative.x*0.003)
	if event is InputEventScreenTouch:
		if event.pressed and event.position.y < 400:
			look_touch = event.index
			previous_touch = event.position
		elif not event.pressed and event.index == look_touch:
			look_touch = -1
	if event is InputEventScreenDrag and event.index == look_touch:
		player.rotate_y(-(event.position.x-previous_touch.x)*0.005)
		previous_touch = event.position

func tone(freq: float) -> void:
	var wav := AudioStreamWAV.new()
	wav.mix_rate = 22050
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	var raw := PackedByteArray()
	raw.resize(8800)
	for i in range(4400):
		var sample := int(sin(TAU*freq*float(i)/22050.0)*12000.0*(1.0-float(i)/4400.0))
		raw.encode_s16(i*2,sample)
	wav.data = raw
	sound.stream = wav
	sound.play()

func _physics_process(delta: float) -> void:
	if ended: return
	var direction := Vector2(Input.get_axis("ui_left","ui_right"),Input.get_axis("ui_up","ui_down"))+touch_dir
	if Input.is_key_pressed(KEY_A): direction.x -= 1
	if Input.is_key_pressed(KEY_D): direction.x += 1
	if Input.is_key_pressed(KEY_W): direction.y -= 1
	if Input.is_key_pressed(KEY_S): direction.y += 1
	direction = direction.limit_length()
	var v := player.global_transform.basis * Vector3(direction.x,0,direction.y)
	var speed := 4.3 if Input.is_key_pressed(KEY_SHIFT) else 2.7
	player.velocity = Vector3(v.x*speed,0,v.z*speed)
	player.move_and_slide()
	battery = clampf(battery+(-delta*0.7 if light.visible else delta*0.5),0,100)
	if battery <= 0: light.visible = false
	hud.text = "Fener %d%%    Anahtar %d/3" % [int(battery),collected]
	for k in keys.duplicate():
		k.rotate_y(delta*1.5)
		if player.position.distance_to(k.position)<0.85:
			keys.erase(k)
			k.queue_free()
			collected += 1
			tone(700)
	if collected == 3 and player.position.distance_to(Vector3(13.5,0.12,12.5))<0.9:
		finish("KURTULDUN! Yeniden baslatmak icin R")
	var delta_enemy := player.position-monster.position
	if delta_enemy.length()<8.0 and delta_enemy.length()>0.4:
		var next := delta_enemy.normalized()*delta*0.9
		var space := get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(monster.position+Vector3.UP,monster.position+next+Vector3.UP)
		if space.intersect_ray(query).is_empty(): monster.position += Vector3(next.x,0,next.z)
		monster.look_at(Vector3(player.position.x,monster.position.y,player.position.z),Vector3.UP)
	if delta_enemy.length()<0.85:
		finish("YARATIK SENI BULDU! Yeniden baslatmak icin R")
	overlay.color.a = clampf((2.7-delta_enemy.length())*0.11,0,0.25)

func finish(msg: String) -> void:
	ended = true
	tone(110)
	hud.text = msg
