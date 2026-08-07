extends Control

var value := Vector2.ZERO
var base_color := Color(0.10, 0.12, 0.15, 0.48)
var ring_color := Color(0.82, 0.86, 0.90, 0.62)
var knob_color := Color(0.82, 0.86, 0.90, 0.72)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_value(new_value: Vector2) -> void:
	value = new_value.limit_length(1.0)
	queue_redraw()

func reset() -> void:
	set_value(Vector2.ZERO)

func _draw() -> void:
	var center := size * 0.5
	var radius: float = minf(size.x, size.y) * 0.46
	draw_circle(center, radius, base_color)
	draw_arc(center, radius, 0.0, TAU, 64, ring_color, 4.0, true)
	draw_circle(center + value * radius * 0.52, radius * 0.34, knob_color)
	draw_arc(center + value * radius * 0.52, radius * 0.34, 0.0, TAU, 48, ring_color, 3.0, true)
