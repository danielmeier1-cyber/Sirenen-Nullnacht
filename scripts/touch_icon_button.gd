extends Button

enum IconType { HAND, CARTRIDGE }

const FIRE_CARTRIDGE_TEXTURE := preload("res://assets/ui/fire_cartridge_fire_45ccw.png")

var icon_type: IconType = IconType.HAND
var hand_closed := false

func _ready() -> void:
	text = ""
	focus_mode = Control.FOCUS_NONE
	add_theme_stylebox_override("normal", _button_style(Color(0.05, 0.07, 0.09, 0.72), Color(0.72, 0.76, 0.72, 0.75)))
	add_theme_stylebox_override("hover", _button_style(Color(0.08, 0.10, 0.12, 0.82), Color(0.90, 0.82, 0.56, 0.9)))
	add_theme_stylebox_override("pressed", _button_style(Color(0.24, 0.17, 0.08, 0.9), Color(1.0, 0.72, 0.20, 1.0)))
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	queue_redraw()

func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(28)
	return style

func _on_button_down() -> void:
	if icon_type == IconType.HAND:
		hand_closed = true
		queue_redraw()

func _on_button_up() -> void:
	if icon_type == IconType.HAND:
		hand_closed = false
		queue_redraw()

func _draw() -> void:
	if icon_type == IconType.HAND:
		_draw_fist() if hand_closed else _draw_open_hand()
	else:
		_draw_cartridge()

func _draw_open_hand() -> void:
	var c := Color("f1c27d")
	var outline := Color("5a3b22")
	var palm := Rect2(size.x * 0.37, size.y * 0.39, size.x * 0.32, size.y * 0.39)
	draw_style_box(_rounded(c, outline, 12.0), palm)
	var fingers := [
		Rect2(size.x * 0.36, size.y * 0.17, size.x * 0.075, size.y * 0.31),
		Rect2(size.x * 0.445, size.y * 0.10, size.x * 0.075, size.y * 0.37),
		Rect2(size.x * 0.53, size.y * 0.13, size.x * 0.075, size.y * 0.34),
		Rect2(size.x * 0.615, size.y * 0.21, size.x * 0.075, size.y * 0.28)
	]
	for finger in fingers:
		draw_style_box(_rounded(c, outline, 7.0), finger)
	var thumb := PackedVector2Array([
		Vector2(size.x * 0.39, size.y * 0.48), Vector2(size.x * 0.22, size.y * 0.37),
		Vector2(size.x * 0.17, size.y * 0.46), Vector2(size.x * 0.37, size.y * 0.65)
	])
	draw_colored_polygon(thumb, c)
	draw_polyline(thumb + PackedVector2Array([thumb[0]]), outline, 3.0, true)

func _draw_fist() -> void:
	var c := Color("f1c27d")
	var outline := Color("5a3b22")
	var fist := Rect2(size.x * 0.25, size.y * 0.27, size.x * 0.52, size.y * 0.48)
	draw_style_box(_rounded(c, outline, 17.0), fist)
	for i in 3:
		var x := size.x * (0.38 + i * 0.13)
		draw_line(Vector2(x, size.y * 0.29), Vector2(x, size.y * 0.50), outline, 3.0, true)
	draw_arc(Vector2(size.x * 0.51, size.y * 0.57), size.x * 0.19, PI, TAU, 20, outline, 3.0, true)

func _draw_cartridge() -> void:
	var icon_size := minf(size.x, size.y) * 0.82
	var icon_rect := Rect2((size - Vector2.ONE * icon_size) * 0.5, Vector2.ONE * icon_size)
	draw_texture_rect(FIRE_CARTRIDGE_TEXTURE, icon_rect, false)

func _rounded(fill: Color, border: Color, radius: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(int(radius))
	return style
