extends Node2D

const MAP = [
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
var player := Vector2(1.5, 1.5)
var facing := 0.0
var enemy := Vector2(12.5, 12.5)
var keys := [Vector2(13.5,1.5),Vector2(1.5,12.5),Vector2(7.5,8.5)]
var found := 0
var battery := 100.0
var flashlight := true
var ended := false
var message := ""
var buttons := {}
var touch := {}
var touch_look_id := -1
var last_touch_x := 0.0
var sound_player: AudioStreamPlayer
var scare_cooldown := 0.0
var wall_tex: Texture2D
var floor_tex: Texture2D
var monster_tex: Texture2D

func load_hf_texture(asset: String) -> Texture2D:
	var path := "res://assets/" + asset + ".webp.b64"
	if not FileAccess.file_exists(path):
		return null
	var base64 := FileAccess.get_file_as_string(path).strip_edges()
	var bytes := Marshalls.base64_to_raw(base64)
	var image := Image.new()
	if image.load_webp_from_buffer(bytes) != OK:
		return null
	return ImageTexture.create_from_image(image)


func _ready() -> void:
	wall_tex = load_hf_texture("wall")
	floor_tex = load_hf_texture("floor")
	monster_tex = load_hf_texture("monster")
	sound_player = AudioStreamPlayer.new()
	add_child(sound_player)
	sound_player.volume_db = -15.0
	set_process(true)

func solid(p: Vector2) -> bool:
	var cx := int(floor(p.x))
	var cy := int(floor(p.y))
	return cy < 0 or cy >= MAP.size() or cx < 0 or cx >= MAP[cy].length() or MAP[cy][cx] != "0"

func beep(freq: float, duration: float, volume: float = 0.15) -> void:
	var sample_rate := 22050
	var frames := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var envelope := pow(1.0 - float(i)/float(frames),2.0)
		var v := sin(TAU * freq * float(i)/float(sample_rate)) * envelope * volume
		var pcm := int(clampf(v,-1.0,1.0)*32767.0)
		data.encode_s16(i*2,pcm)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	sound_player.stream = stream
	sound_player.play()

func reset() -> void:
	player = Vector2(1.5,1.5)
	facing = 0.0
	enemy = Vector2(12.5,12.5)
	keys = [Vector2(13.5,1.5),Vector2(1.5,12.5),Vector2(7.5,8.5)]
	found = 0
	battery = 100.0
	flashlight = true
	ended = false
	message = ""

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			flashlight = not flashlight
		if event.keycode == KEY_R and ended:
			reset()
	if event is InputEventScreenTouch:
		var p := event.position
		var w := get_viewport_rect().size.x
		var h := get_viewport_rect().size.y
		if event.pressed:
			if ended:
				reset()
			elif p.y > h - 125:
				if p.x < 85: touch[event.index] = "left"
				elif p.x < 170: touch[event.index] = "forward"
				elif p.x < 255: touch[event.index] = "back"
				elif p.x < 340: touch[event.index] = "right"
				elif p.x > w - 110: flashlight = not flashlight
			else:
				touch_look_id = event.index
				last_touch_x = p.x
		else:
			touch.erase(event.index)
			if event.index == touch_look_id: touch_look_id = -1
	if event is InputEventScreenDrag and event.index == touch_look_id:
		facing += (event.position.x - last_touch_x) * 0.007
		last_touch_x = event.position.x
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		facing += event.relative.x * 0.004

func active(name: String) -> bool:
	return touch.values().has(name)

func _process(delta: float) -> void:
	if ended:
		queue_redraw()
		return
	var turn := int(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or active("right")) - int(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or active("left"))
	facing += turn * delta * 2.0
	var forward := int(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or active("forward")) - int(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or active("back"))
	var speed := 3.3 if Input.is_key_pressed(KEY_SHIFT) else 2.2
	var step := Vector2(cos(facing),sin(facing)) * forward * speed * delta
	if not solid(player + Vector2(step.x,0)): player.x += step.x
	if not solid(player + Vector2(0,step.y)): player.y += step.y
	if flashlight:
		battery = maxf(0.0,battery - delta * 0.65)
		if battery <= 0: flashlight = false
	else:
		battery = minf(100.0,battery + delta * 0.85)
	for i in range(keys.size()-1,-1,-1):
		if player.distance_to(keys[i]) < 0.5:
			keys.remove_at(i)
			found += 1
			beep(740.0,0.18)
	if found == 3 and player.distance_to(Vector2(13.5,12.5)) < 0.7:
		ended = true
		message = "KURTULDUN! R / dokun: yeniden oyna"
		beep(960.0,0.65)
	var d := player.distance_to(enemy)
	scare_cooldown = maxf(0.0,scare_cooldown-delta)
	if d < 2.7 and scare_cooldown <= 0.0:
		beep(68.0,0.22,0.2)
		scare_cooldown = 1.3
	if d < 8.0 and d > 0.01:
		var v := (player-enemy).normalized() * delta * 0.85
		if not solid(enemy + Vector2(v.x,0)): enemy.x += v.x
		if not solid(enemy + Vector2(0,v.y)): enemy.y += v.y
	if player.distance_to(enemy) < 0.52:
		ended = true
		message = "SENI BULDU! R / dokun: yeniden oyna"
		beep(95.0,0.9,0.5)
	queue_redraw()

func draw_label(pos: Vector2, s: String, size: int = 22, color: Color = Color.WHITE) -> void:
	draw_string(ThemeDB.fallback_font,pos,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _draw() -> void:
	var sz := get_viewport_rect().size
	var w := sz.x
	var h := sz.y
	draw_rect(Rect2(0,0,w,h/2),Color(0.025,0.038,0.055))
	draw_rect(Rect2(0,h/2,w,h/2),Color(0.07,0.065,0.055))
	if floor_tex:
		for fy in range(int(h/2),int(h),5):
			var perspective := (float(fy)-h/2.0)/maxf(1.0,h/2.0)
			var brightness := 0.06+perspective*0.15
			var uv_y := fposmod(player.y+1.0/maxf(0.03,perspective),1.0)
			draw_texture_rect_region(floor_tex,Rect2(0,fy,w,5),Rect2(0,uv_y*floor_tex.get_height(),floor_tex.get_width(),5),Color(brightness,brightness,brightness))
	var depths: Array[float] = []
	var stride := 3
	for ix in range(0,int(w),stride):
		var angle := facing + atan((float(ix)/w-0.5)*1.25)
		var distance := 0.05
		while distance < 18.0 and not solid(player+Vector2(cos(angle),sin(angle))*distance):
			distance += 0.045
		distance *= cos(angle-facing)
		depths.append(distance)
		var wall_height := minf(h*2.0,h/maxf(0.15,distance))
		var intensity := (maxf(0.035,1.0-abs(float(ix)/w-0.5)*1.6) if flashlight else 0.065) / (1.0+distance*0.22)
		var top := h/2-wall_height/2
		if wall_tex:
			var hit := player+Vector2(cos(angle),sin(angle))*distance/maxf(0.01,cos(angle-facing))
			var uv := fposmod(hit.x if abs(sin(angle)) > abs(cos(angle)) else hit.y,1.0)
			var tex_rect := Rect2(uv*wall_tex.get_width(),0,maxf(1.0,wall_tex.get_width()*0.008),wall_tex.get_height())
			draw_texture_rect_region(wall_tex,Rect2(ix,top,stride+1,wall_height),tex_rect,Color(intensity*2.1,intensity*2.1,intensity*2.1))
		else:
			draw_rect(Rect2(ix,top,stride+1,wall_height),Color(0.45,0.62,0.75)*intensity)
	var sprites: Array = []
	for k in keys: sprites.append([k,"key"])
	sprites.append([Vector2(13.5,12.5),"exit"])
	sprites.append([enemy,"enemy"])
	sprites.sort_custom(func(a,b): return player.distance_to(a[0]) > player.distance_to(b[0]))
	for item in sprites:
		var pos: Vector2 = item[0]
		var kind: String = item[1]
		var d := player.distance_to(pos)
		if d < 0.1: continue
		var ang := wrapf(atan2(pos.y-player.y,pos.x-player.x)-facing,-PI,PI)
		if abs(ang)>0.65: continue
		var screen_x := (0.5+tan(ang)/1.25)*w
		var column := clampi(int(screen_x/stride),0,depths.size()-1)
		if depths[column] < d-0.3: continue
		var sprite_height := minf(h*1.5,h/d*(0.3 if kind=="key" else 1.0))
		var color := Color(0.9,0.73,0.18) if kind=="key" else (Color(0.18,0.72,0.3) if kind=="exit" and found==3 else (Color(0.42,0.13,0.1) if kind=="exit" else Color(0.1,0.01,0.025)))
		if kind == "enemy" and monster_tex:
			draw_texture_rect(monster_tex,Rect2(screen_x-sprite_height*0.34,h/2-sprite_height/2,sprite_height*0.68,sprite_height),false,Color(0.8,0.8,0.8))
		else:
			draw_rect(Rect2(screen_x-sprite_height*0.15,h/2-sprite_height/2,sprite_height*0.3,sprite_height),color)
		if kind=="enemy" and monster_tex == null:
			draw_rect(Rect2(screen_x-sprite_height*0.08,h/2-sprite_height*0.25,sprite_height*0.045,sprite_height*0.025),Color.RED)
			draw_rect(Rect2(screen_x+sprite_height*0.035,h/2-sprite_height*0.25,sprite_height*0.045,sprite_height*0.025),Color.RED)
	draw_label(Vector2(16,32),"Fener: %d%%   Anahtar: %d/3" % [int(battery),found],23)
	draw_label(Vector2(16,60),"WASD: hareket  |  F: fener  |  SHIFT: kos",16,Color(0.8,0.8,0.8))
	if player.distance_to(enemy) < 3.0:
		draw_rect(Rect2(0,0,w,8),Color(0.6,0.02,0.02,0.6))
	if found == 3:
		draw_label(Vector2(w*0.37,35),"CIKISA GIT!",23,Color(0.3,1.0,0.5))
	for i in range(4):
		var labels := ["<","^","v",">"]
		draw_rect(Rect2(10+i*85,h-90,76,76),Color(0.25,0.26,0.3,0.7))
		draw_label(Vector2(36+i*85,h-42),labels[i],26)
	draw_rect(Rect2(w-100,h-90,90,76),Color(0.4,0.2,0.15,0.8))
	draw_label(Vector2(w-83,h-42),"F",26)
	if ended:
		draw_rect(Rect2(0,h/2-65,w,130),Color(0,0,0,0.9))
		draw_label(Vector2(w*0.15,h/2+10),message,28,Color(1,0.3,0.3))
