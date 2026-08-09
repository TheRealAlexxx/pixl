extends CanvasLayer

const THEME := preload("res://themes/main_theme.tres")
const GAMEPLAY_SCENES := ["village", "open_world", "house_interior", "shop_interior"]
const MAP_SIZE := 132.0
const WORLD_SCALE := 0.22
const COLOR_SELF := Color(1, 0.819608, 0.4)
const COLOR_OTHER := Color(0.290196, 0.870588, 0.501961)
const COLOR_NPC := Color(0.62, 0.58, 0.5)
const COLOR_BG := Color(0.039216, 0.031373, 0.019608, 0.72)
const COLOR_BORDER := Color(1, 1, 1, 0.14)

var _root: Control
var _map: Control

func _ready() -> void:
	layer = 95
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = THEME
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)

	_map = Control.new()
	_map.custom_minimum_size = Vector2(MAP_SIZE, MAP_SIZE)
	_map.anchor_left = 1.0
	_map.anchor_right = 1.0
	_map.offset_left = -MAP_SIZE - 12.0
	_map.offset_right = -12.0
	_map.offset_top = 12.0
	_map.offset_bottom = 12.0 + MAP_SIZE
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map.clip_contents = true
	_map.draw.connect(_draw_map)
	_root.add_child(_map)

func _process(_delta: float) -> void:
	var show := _in_gameplay() and not global.ui_blocked()
	_root.visible = show
	if show:
		_map.queue_redraw()

func _draw_map() -> void:
	var full := Rect2(Vector2.ZERO, Vector2(MAP_SIZE, MAP_SIZE))
	_map.draw_rect(full, COLOR_BG)
	var world := get_tree().current_scene
	if world == null or not "remote_players" in world:
		_map.draw_rect(full, COLOR_BORDER, false, 1.0)
		return
	var me = world.get("_local_player")
	if me == null or not is_instance_valid(me):
		_map.draw_rect(full, COLOR_BORDER, false, 1.0)
		return
	var center := Vector2(MAP_SIZE, MAP_SIZE) / 2.0
	var origin: Vector2 = me.global_position
	_draw_terrain(MapData.scene_key(world), origin, full)
	_map.draw_rect(full, COLOR_BORDER, false, 1.0)
	for child in world.get_children():
		if child is CharacterBody2D and child.has_method("npc_id"):
			_draw_dot(center + (child.global_position - origin) * WORLD_SCALE, COLOR_NPC, 2.0)
	var remotes: Dictionary = world.get("remote_players")
	for uid in remotes:
		var rp = remotes[uid]
		if is_instance_valid(rp):
			_draw_dot(center + (rp.global_position - origin) * WORLD_SCALE, COLOR_OTHER, 3.0)
	_draw_dot(center, COLOR_SELF, 3.0)

# Terrain under the dots, cut out of the PNG that scripts/tools/bake_world_map.gd
# renders. No-op until that has been run, which leaves the old flat-rect minimap.
func _draw_terrain(key: String, origin: Vector2, dest: Rect2) -> void:
	if key == "":
		return
	var tex := MapData.texture(key)
	if tex == null:
		return
	var img_scale := MapData.image_scale(key)
	if img_scale == Vector2.ZERO:
		return
	# The minimap shows MAP_SIZE screen px at WORLD_SCALE, so it covers this many
	# world px in each direction from the player.
	var half_world := (MAP_SIZE * 0.5) / WORLD_SCALE
	var top_left := MapData.world_to_image(key, origin - Vector2(half_world, half_world))
	_map.draw_texture_rect_region(tex, dest, Rect2(top_left, Vector2(half_world, half_world) * 2.0 * img_scale))

func _draw_dot(pos: Vector2, color: Color, half: float) -> void:
	var edge := 3.0
	pos.x = clampf(pos.x, edge, MAP_SIZE - edge)
	pos.y = clampf(pos.y, edge, MAP_SIZE - edge)
	_map.draw_rect(Rect2(pos - Vector2(half, half), Vector2(half, half) * 2.0), color)

func _in_gameplay() -> bool:
	var cur := get_tree().current_scene
	return cur != null and GAMEPLAY_SCENES.has(cur.scene_file_path.get_file().get_basename())
