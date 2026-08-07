extends Node3D

const PLAYER := preload("res://scripts/player.gd")
const ZOMBIE := preload("res://scripts/zombie.gd")
const VIRTUAL_JOYSTICK := preload("res://scripts/virtual_joystick.gd")
const TOUCH_ICON_BUTTON := preload("res://scripts/touch_icon_button.gd")
const SUBURBAN_HOUSE := preload("res://assets/environment/amerikanisches_vorstadthaus_final_godot.glb")

var player: CharacterBody3D
var hud: CanvasLayer
var objective_label: Label
var story_label: Label
var health_label: Label
var ammo_label: Label
var fade: ColorRect
var objective := 0
var kills := 0
var intro_lines := [
	"23:47 Uhr – Zuhause. Ein gewöhnlicher Donnerstag.",
	"MARA: Jonas? Die Sirenen … das ist kein Probealarm.",
	"RADIO: Bleiben Sie in Ihren Häusern. Verriegeln Sie Türen und Fenster.",
	"LENA: Papa, warum schreien die Leute draußen?",
	"JONAS: Ihr bleibt hinter mir. Ich sehe nach der Tür."
]

func _ready() -> void:
	build_environment()
	build_house()
	spawn_player()
	build_hud()
	await play_intro()
	set_objective(1)

func mat(color: Color, rough := 0.8, emission := Color.BLACK) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 2.2
	return m

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, collision := true) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.position = pos
	mesh_node.material_override = mat(color)
	parent.add_child(mesh_node)
	if collision:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
		mesh_node.add_child(body)
	return mesh_node

func build_environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("05070a")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("33404d")
	e.ambient_light_energy = 0.32
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.fog_enabled = true
	e.fog_light_color = Color("19202a")
	e.fog_density = 0.025
	env.environment = e
	add_child(env)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-48,-25,0)
	moon.light_color = Color("8aa4c2")
	moon.light_energy = 0.35
	moon.shadow_enabled = true
	add_child(moon)

func build_house() -> void:
	var level := Node3D.new()
	level.name = "Amerikanisches_Vorstadthaus"
	add_child(level)
	var house := SUBURBAN_HOUSE.instantiate()
	house.name = "HouseModel"
	level.add_child(house)
	_add_house_collisions(house)
	# Story interaction points are separate from the imported art asset.
	var door := box(level, Vector3(-0.45,1.2,-4.38), Vector3(1.0,2.2,0.12), Color("2d1b14"), true)
	door.name = "FrontDoor"
	door.visible = false
	var radio := box(level, Vector3(-4.5,1.22,3.55), Vector3(0.55,0.28,0.28), Color("262a2e"), true)
	radio.name = "Radio"
	var bat := box(level, Vector3(4.45,0.72,-0.65), Vector3(0.16,1.0,0.16), Color("562b1d"), true)
	bat.rotation_degrees.z = 68
	bat.name = "BatPickup"
	var red := OmniLight3D.new()
	red.position = Vector3(2.5,2.55,-1.0)
	red.light_color = Color("e21b16")
	red.light_energy = 2.0
	red.omni_range = 8.0
	level.add_child(red)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(-3.5,2.55,2.5)
	lamp.light_color = Color("ffbc72")
	lamp.light_energy = 1.2
	lamp.omni_range = 6.0
	level.add_child(lamp)

func _add_house_collisions(root: Node) -> void:
	var structure_tokens := [
		"Grundstueck", "Fundament", "Boden", "Decke", "Pfeiler", "Fensterbruestung",
		"Fenstersturz", "Wand", "Treppenstufe", "Veranda_Deck", "Terrasse", "Zuweg"
	]
	for child in root.get_children():
		if child is MeshInstance3D:
			var mesh_node := child as MeshInstance3D
			var structural := false
			for token in structure_tokens:
				if String(mesh_node.name).contains(token):
					structural = true
					break
			if structural:
				mesh_node.create_trimesh_collision()
		_add_house_collisions(child)

func spawn_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Jonas"
	player.set_script(PLAYER)
	player.position = Vector3(1.8,1.05,0.75)
	add_child(player)
	player.health_changed.connect(func(v): health_label.text = "GESUNDHEIT  %d" % v if health_label else "")
	player.ammo_changed.connect(func(v): ammo_label.text = "MUNITION  %d" % v if ammo_label else "")
	player.interacted.connect(_on_interact)
	player.died.connect(_on_player_died)

func build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.08,0,0,0.10)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(vignette)
	objective_label = Label.new()
	objective_label.position = Vector2(28,24)
	objective_label.add_theme_font_size_override("font_size",22)
	objective_label.add_theme_color_override("font_color",Color("e6d7c2"))
	hud.add_child(objective_label)
	story_label = Label.new()
	story_label.set_anchors_preset(Control.PRESET_CENTER)
	story_label.position = Vector2(-420,190)
	story_label.size = Vector2(840,90)
	story_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_label.add_theme_font_size_override("font_size",25)
	story_label.add_theme_color_override("font_color",Color("f2e7db"))
	hud.add_child(story_label)
	health_label = Label.new()
	health_label.position = Vector2(28,665)
	health_label.text = "GESUNDHEIT  100"
	health_label.add_theme_font_size_override("font_size",20)
	hud.add_child(health_label)
	ammo_label = Label.new()
	ammo_label.position = Vector2(1080,665)
	ammo_label.text = "UNBEWAFFNET"
	ammo_label.add_theme_font_size_override("font_size",20)
	hud.add_child(ammo_label)
	var cross := Label.new()
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.position = Vector2(-8,-15)
	cross.text = "+"
	cross.add_theme_font_size_override("font_size",24)
	cross.add_theme_color_override("font_color",Color(0.9,0.9,0.85,0.7))
	hud.add_child(cross)
	build_touch_controls()
	fade = ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color.BLACK
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(fade)
	var tween := create_tween()
	tween.tween_property(fade,"color:a",0.0,2.2)

func build_touch_controls() -> void:
	var move_pad := Control.new()
	move_pad.set_script(VIRTUAL_JOYSTICK)
	move_pad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	move_pad.position = Vector2(28,-218)
	move_pad.size = Vector2(190,190)
	move_pad.name = "MovePad"
	move_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(move_pad)
	var look_pad := Control.new()
	look_pad.set_script(VIRTUAL_JOYSTICK)
	look_pad.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	look_pad.position = Vector2(-218,-218)
	look_pad.size = Vector2(190,190)
	look_pad.name = "LookPad"
	look_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(look_pad)
	var fire_btn := Button.new()
	fire_btn.set_script(TOUCH_ICON_BUTTON)
	fire_btn.icon_type = 1 # Patrone
	fire_btn.name = "FireCartridgeButton"
	fire_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	fire_btn.position = Vector2(-350,-205)
	fire_btn.size = Vector2(112,82)
	fire_btn.button_down.connect(func(): player.shoot())
	hud.add_child(fire_btn)
	var action_btn := Button.new()
	action_btn.set_script(TOUCH_ICON_BUTTON)
	action_btn.icon_type = 0 # Hand, bei Berührung Faust
	action_btn.name = "ActionHandButton"
	action_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	action_btn.position = Vector2(-350,-105)
	action_btn.size = Vector2(112,70)
	action_btn.button_down.connect(func(): player.try_interact())
	hud.add_child(action_btn)
	player.touch_pad = move_pad
	player.look_pad = look_pad

func play_intro() -> void:
	player.can_move = false
	for line in intro_lines:
		story_label.text = line
		await get_tree().create_timer(2.3).timeout
	story_label.text = ""
	player.can_move = true

func set_objective(id: int) -> void:
	objective = id
	match id:
		1: objective_label.text = "ZIEL  •  Schalte das Radio ein"
		2: objective_label.text = "ZIEL  •  Finde etwas zur Verteidigung"
		3: objective_label.text = "ZIEL  •  Halte die Wohnungstür"
		4: objective_label.text = "ZIEL  •  Überlebe den ersten Ansturm (%d/3)" % kills
		5: objective_label.text = "KAPITEL ABGESCHLOSSEN  •  Die Stadt ist gefallen"

func _on_interact(target: Node) -> void:
	if target.name == "Radio" and objective == 1:
		story_label.text = "RADIO: Infizierte reagieren aggressiv. Meiden Sie Körperkontakt."
		set_objective(2)
		await get_tree().create_timer(3.0).timeout
		story_label.text = ""
	elif target.name == "BatPickup" and objective == 2:
		target.queue_free()
		player.arm_player()
		set_objective(3)
	elif target.name == "FrontDoor" and objective == 3:
		story_label.text = "Etwas schlägt von außen gegen die Tür. Das Holz splittert."
		await get_tree().create_timer(2.0).timeout
		story_label.text = ""
		set_objective(4)
		spawn_wave()

func spawn_wave() -> void:
	for i in 3:
		var z := CharacterBody3D.new()
		z.set_script(ZOMBIE)
		z.position = Vector3(-0.45 + (i-1)*1.2,1.0,-3.7-i*0.25)
		z.target = player
		z.died.connect(_on_zombie_died)
		add_child(z)

func _on_zombie_died() -> void:
	kills += 1
	set_objective(4)
	if kills >= 3:
		set_objective(5)
		story_label.text = "MARA: Das waren unsere Nachbarn …\nJONAS: Wir müssen vor Sonnenaufgang hier raus."
		player.can_move = false

func _on_player_died() -> void:
	story_label.text = "DU BIST GESTORBEN\nBerühre den Bildschirm zum Neustart"
	player.can_move = false
