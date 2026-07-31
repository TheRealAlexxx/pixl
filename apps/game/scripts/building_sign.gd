extends Node

# A persistent floating signboard: a big pixel label on a dark, gold-bordered
# panel, scaled to hang above a building or station in the pixel-art world so
# players can tell at a glance which house is the Shop, which NPC logs Projects,
# etc. Built entirely in code (no scene) via make(), which returns a detached
# Node2D the caller parents wherever it wants.

const FONT := preload("res://assets/fonts/PixelifySans.ttf")
const ACCENT := Color(1, 0.819608, 0.4)
const WORLD_SCALE := 1.0 / 3.2  # a touch bigger than the ~1/3.5 name tags

static func make(text: String, y: float = -64.0) -> Node2D:
	var fsize := 34
	var pad := Vector2(14, 8)
	var tw: float = FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	var th: float = FONT.get_height(fsize)
	var box := Vector2(tw, th) + pad * 2.0

	var holder := Node2D.new()
	holder.z_index = 20

	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.055, 0.05, 0.09, 0.92)
	sb.border_color = ACCENT
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(5)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 4
	panel.add_theme_stylebox_override("panel", sb)
	panel.size = box
	panel.position = Vector2.ZERO
	holder.add_child(panel)

	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", fsize)
	label.add_theme_color_override("font_color", ACCENT)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = box
	label.position = Vector2.ZERO
	holder.add_child(label)

	holder.scale = Vector2.ONE * WORLD_SCALE
	holder.position = Vector2(-box.x * WORLD_SCALE / 2.0, y)
	return holder
