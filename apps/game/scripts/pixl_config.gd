class_name PixlConfig
extends RefCounted

## Reads res://pixl.json - the copy of packages/config/pixl.json that
## `bun run config:sync` writes into this project. The game cannot import the
## workspace package (it runs from an exported PCK), so a synced copy is the way
## the launch date, name and URLs reach GDScript without being retyped here.
##
## Edit packages/config/pixl.json and re-run the sync - never edit res://pixl.json.

const PATH := "res://pixl.json"

static var _data: Dictionary = {}
static var _loaded := false

static func name() -> String:
	return String(_value("name", "Pixl"))

static func tagline() -> String:
	return String(_value("tagline", ""))

## Launch instant as a Unix timestamp. 0 when the config is missing.
static func launch_unix() -> int:
	return _iso_to_unix(String(_value("launchDate", "")))

static func has_launched() -> bool:
	var at := launch_unix()
	return at > 0 and Time.get_unix_time_from_system() >= at

static func url(key: String, fallback: String = "") -> String:
	var urls = _value("urls", {})
	if typeof(urls) != TYPE_DICTIONARY:
		return fallback
	return String(urls.get(key, fallback))

static func _value(key: String, fallback: Variant) -> Variant:
	_load()
	return _data.get(key, fallback)

static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(PATH):
		push_warning("[PixlConfig] %s missing - run `bun run config:sync`" % PATH)
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_data = parsed
	else:
		push_warning("[PixlConfig] %s is malformed" % PATH)

# Time.get_unix_time_from_datetime_string handles ISO-8601, but treats a naive
# string as UTC - which is what the config promises, so the trailing Z is safe
# to strip rather than something to parse.
static func _iso_to_unix(iso: String) -> int:
	if iso == "":
		return 0
	return int(Time.get_unix_time_from_datetime_string(iso.trim_suffix("Z")))
