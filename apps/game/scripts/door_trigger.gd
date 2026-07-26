extends Area2D

const MONOCRAFT := preload("res://assets/fonts/PixelifySans.ttf")
const SIGN := preload("res://scripts/building_sign.gd")

@export var target: String = "house"
## Big always-on signboard hung above the building (e.g. "SHOP", "HOME").
## Leave blank for no sign.
@export var sign_name: String = ""
## Vertical offset of the sign; raise (more negative) for taller buildings.
@export var sign_y: float = -66.0

@onready var label: Label = $Label

var _glow: Sprite2D

func _ready() -> void:
	_setup_night_glow()
	if sign_name != "":
		add_child(SIGN.make(sign_name, sign_y))
	label.add_theme_font_override("font", MONOCRAFT)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1, 0.819608, 0.4))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 6)
	label.scale = Vector2.ONE / 3.5
	label.reset_size()
	label.position = Vector2(-label.size.x * label.scale.x / 2.0, -26.0)

func _setup_night_glow() -> void:
	_glow = Sprite2D.new()
	_glow.texture = DayNight.glow_texture()
	_glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_glow.z_index = 1
	_glow.position = Vector2(0, -6)
	_glow.scale = Vector2.ONE * 1.4
	_glow.modulate = Color(1.0, 0.82, 0.5, 0.0)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = mat
	add_child(_glow)

func _process(_delta: float) -> void:
	if _glow:
		_glow.modulate.a = DayNight.night_amount() * 0.85

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("player") and body.is_local:
		global.player_in_range = true
		global.active_door_pos = global_position
		global.active_door_target = target
		label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("player") and body.is_local:
		global.player_in_range = false
		label.visible = false
