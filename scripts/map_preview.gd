class_name MapPreview
extends Control

var map_index: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var data: Dictionary = CourseData.MAPS[map_index]
	var ink := Color(data.edge)
	var bg := Color(data.sky).lightened(0.07)
	draw_style_box(pill(bg, 18), Rect2(Vector2.ZERO, size))
	var scale_factor := size.x / 180.0
	var s := Vector2(scale_factor, size.y / 110.0)
	for i in range(3):
		draw_circle(Vector2(25 + i * 65, 22 + (i % 2) * 22) * s, 17 * scale_factor, Color(1, 1, 1, 0.25))
	for i in range(4):
		var x: float = 36 + i * 35
		var y: float = 82 - i * 16 + sin(i * 2 + map_index) * 5
		var diamond := PackedVector2Array([Vector2(x - 23, y), Vector2(x, y - 11), Vector2(x + 23, y), Vector2(x, y + 11)])
		var side := PackedVector2Array([Vector2(x - 23, y), Vector2(x, y + 11), Vector2(x + 23, y), Vector2(x + 23, y + 8), Vector2(x, y + 19), Vector2(x - 23, y + 8)])
		for j in range(diamond.size()): diamond[j] *= s
		for j in range(side.size()): side[j] *= s
		draw_colored_polygon(side, ink)
		draw_colored_polygon(diamond, Color(data.floor).lightened(0.12))
		if i > 0 and i < 3:
			match map_index:
				0, 5:
					draw_line(Vector2(x - 14, y - 5) * s, Vector2(x + 14, y - 12) * s, Color("f685a1"), 5 * scale_factor, true)
				1:
					draw_circle(Vector2(x, y - 9) * s, 8 * scale_factor, Color("f2fdff"))
				2:
					draw_colored_polygon(PackedVector2Array([Vector2(x - 6, y) * s, Vector2(x, y - 24) * s, Vector2(x + 6, y) * s]), Color("ffb960"))
				3:
					draw_arc(Vector2(x, y - 5) * s, 10 * scale_factor, 0, TAU, 24, Color("c5a1e6"), 4 * scale_factor, true)
				4:
					draw_line(Vector2(x, y) * s, Vector2(x, y - 13) * s, Color("f4e2ba"), 4 * scale_factor)
					draw_circle(Vector2(x, y - 13) * s, 8 * scale_factor, Color("f29184"))
	var egg_pos := Vector2(36, 68) * s
	draw_circle(egg_pos + Vector2(0, 7), 8 * scale_factor, Color(0.2, 0.3, 0.4, 0.14))
	draw_style_box(pill(Color("ffda76"), 14), Rect2(egg_pos - Vector2(7, 13) * s, Vector2(15, 19) * s))
	for side in [-1, 1]: draw_circle(egg_pos + Vector2(side * 2.5, -5) * s, 1.0 * scale_factor, Color("39435a"))

func pill(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
