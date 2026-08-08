class_name MapData
extends RefCounted

## Runtime side of scripts/tools/bake_world_map.gd: hands the baked terrain image
## for a scene to whoever is drawing a map, plus the world-space rect it covers
## so world coordinates can be turned into pixels on that image.
##
## Everything here returns null / an empty rect when the bake has not been run
## yet, so both HUDs keep working (flat placeholder) on a fresh checkout.

const DIR := "res://assets/map"
const BOUNDS_PATH := DIR + "/bounds.json"

static var _worlds: Dictionary = {}
static var _textures: Dictionary = {}
static var _loaded := false

## Scene key for whatever is on screen - matches the filenames the baker writes.
static func scene_key(scene: Node) -> String:
	if scene == null or scene.scene_file_path == "":
		return ""
	return scene.scene_file_path.get_file().get_basename()

static func has(key: String) -> bool:
	_load()
	return _worlds.has(key)

## World-space rect the baked image covers. Rect2() if there is no bake.
static func bounds(key: String) -> Rect2:
	_load()
	var w = _worlds.get(key)
	if w == null:
		return Rect2()
	return Rect2(float(w["x"]), float(w["y"]), float(w["w"]), float(w["h"]))

static func texture(key: String) -> Texture2D:
	_load()
	if not _worlds.has(key):
		return null
	if _textures.has(key):
		return _textures[key]
	var path := "%s/%s.png" % [DIR, key]
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	# Cached even when null so a missing file is not re-resolved every frame.
	_textures[key] = tex
	return tex

## Image pixels per world pixel. Vector2.ZERO when there is no bake.
static func image_scale(key: String) -> Vector2:
	var b := bounds(key)
	if b.size.x <= 0.0 or b.size.y <= 0.0:
		return Vector2.ZERO
	var w: Dictionary = _worlds[key]
	return Vector2(float(w["iw"]) / b.size.x, float(w["ih"]) / b.size.y)

## Where a world position lands on the baked image, in image pixels.
static func world_to_image(key: String, world_pos: Vector2) -> Vector2:
	var s := image_scale(key)
	if s == Vector2.ZERO:
		return Vector2.ZERO
	return (world_pos - bounds(key).position) * s

static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(BOUNDS_PATH):
		return
	var f := FileAccess.open(BOUNDS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[MapData] bounds.json is malformed, maps will use the placeholder")
		return
	var worlds = parsed.get("worlds")
	if typeof(worlds) == TYPE_DICTIONARY:
		_worlds = worlds
