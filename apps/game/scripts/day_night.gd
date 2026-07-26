extends CanvasModulate

# World day/night tint. This is a CanvasModulate autoload, so it colours every
# CanvasItem on the default canvas (layer 0) — i.e. the game world — while the
# HUDs, which each live on their own CanvasLayer, stay at full brightness.
#
# The time of day is derived from real wall-clock time (Time.get_unix_time...),
# so every client independently lands on the exact same phase without any
# networking — two players standing together always see the same sky.

# Only the outdoor scenes get a sky; interiors and menus stay neutral white.
const OUTDOOR := ["village", "open_world"]
# Real seconds for one full dawn -> day -> dusk -> night -> dawn loop.
const CYCLE_SECONDS := 720.0

var _grad: Gradient

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	color = Color.WHITE
	_grad = Gradient.new()
	# Kept deliberately gentle — even midnight stays plenty bright to play in.
	_grad.offsets = PackedFloat32Array([0.0, 0.22, 0.28, 0.35, 0.65, 0.72, 0.80, 1.0])
	_grad.colors = PackedColorArray([
		Color(0.36, 0.42, 0.68),  # deep night (blue)
		Color(0.36, 0.42, 0.68),
		Color(0.92, 0.72, 0.60),  # dawn (warm)
		Color(1.0, 1.0, 1.0),     # full day
		Color(1.0, 1.0, 1.0),
		Color(0.99, 0.70, 0.47),  # dusk (orange)
		Color(0.36, 0.42, 0.68),  # into night
		Color(0.36, 0.42, 0.68),
	])

func _process(delta: float) -> void:
	var target := Color.WHITE
	if Settings.day_night_enabled and _is_outdoor():
		var phase := fposmod(Time.get_unix_time_from_system() / CYCLE_SECONDS, 1.0)
		target = _grad.sample(phase)
	# Ease toward the target so scene changes and the toggle fade instead of snap.
	color = color.lerp(target, clampf(delta * 2.0, 0.0, 1.0))

func _is_outdoor() -> bool:
	var cur := get_tree().current_scene
	return cur != null and OUTDOOR.has(cur.scene_file_path.get_file().get_basename())
