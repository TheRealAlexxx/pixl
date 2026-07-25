extends CanvasLayer
# On-screen movement joystick + interact button for touchscreens (mobile web).
# Never shown on a desktop/mouse browser — DisplayServer.is_touchscreen_available()
# gates the whole thing off at boot. Feeds the same "move_*"/"interact" actions
# that keyboard input already produces, so nothing downstream needs to know a
# touch happened at all.

const GAMEPLAY_SCENES := ["village", "open_world", "house_interior", "shop_interior"]
const MOVE_ACTIONS := {
	"right": "move_right", "left": "move_left",
	"down": "move_bottom", "up": "move_top",
}

var _root: Control
var _joy_base: Control
var _joy_knob: Control
var _interact_btn: Control

var _joy_center: Vector2 = Vector2.ZERO
var _joy_radius: float = 55.0
var _joy_touch_index: int = -1
var _interact_touch_index: int = -1

func _ready() -> void:
	layer = 96
	if not DisplayServer.is_touchscreen_available():
		set_process(false)
		return
	_build_ui()

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_joy_base = _circle(110, Color(1, 1, 1, 0.14), Color(1, 1, 1, 0.4))
	_joy_base.anchor_left = 0; _joy_base.anchor_right = 0
	_joy_base.anchor_top = 1; _joy_base.anchor_bottom = 1
	_joy_base.offset_left = 36; _joy_base.offset_right = 36 + 110
	_joy_base.offset_top = -166; _joy_base.offset_bottom = -166 + 110
	_root.add_child(_joy_base)

	_joy_knob = _circle(50, Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.7))
	_joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_joy_base.add_child(_joy_knob)
	_center_knob()

	_interact_btn = _circle(84, Color(1, 0.819608, 0.4, 0.28), Color(1, 0.819608, 0.4, 0.75))
	_interact_btn.anchor_left = 1; _interact_btn.anchor_right = 1
	_interact_btn.anchor_top = 1; _interact_btn.anchor_bottom = 1
	_interact_btn.offset_left = -36 - 84; _interact_btn.offset_right = -36
	_interact_btn.offset_top = -150; _interact_btn.offset_bottom = -150 + 84
	var lbl := Label.new()
	lbl.text = "E"
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interact_btn.add_child(lbl)
	_root.add_child(_interact_btn)

func _circle(size: float, fill: Color, ring: Color) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(size, size)
	c.size = Vector2(size, size)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var r := size / 2.0
		c.draw_circle(Vector2(r, r), r, fill)
		c.draw_arc(Vector2(r, r), r - 1.5, 0, TAU, 48, ring, 3.0, true))
	return c

func _center_knob() -> void:
	_joy_knob.position = (_joy_base.size - _joy_knob.size) / 2.0

func _in_gameplay() -> bool:
	var cur := get_tree().current_scene
	return cur != null and GAMEPLAY_SCENES.has(cur.scene_file_path.get_file().get_basename())

func _process(_delta: float) -> void:
	if _root == null:
		return
	var in_game := _in_gameplay() and not global.ui_blocked()
	_root.visible = in_game
	if not in_game:
		_release_joystick()
		_release_interact()

func _input(event: InputEvent) -> void:
	if _root == null or not _root.visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_touch_down(event.index, event.position)
		else:
			_on_touch_up(event.index)
	elif event is InputEventScreenDrag and event.index == _joy_touch_index:
		_update_joystick(event.position)
		get_viewport().set_input_as_handled()

func _on_touch_down(index: int, pos: Vector2) -> void:
	if _joy_touch_index == -1 and pos.distance_to(_joy_base.global_position + _joy_base.size / 2.0) <= _joy_radius * 1.6:
		_joy_touch_index = index
		_joy_center = _joy_base.global_position + _joy_base.size / 2.0
		_update_joystick(pos)
		get_viewport().set_input_as_handled()
	elif _interact_touch_index == -1 and pos.distance_to(_interact_btn.global_position + _interact_btn.size / 2.0) <= _interact_btn.size.x / 2.0 * 1.2:
		_interact_touch_index = index
		_press_interact()
		get_viewport().set_input_as_handled()

func _on_touch_up(index: int) -> void:
	if index == _joy_touch_index:
		_release_joystick()
		get_viewport().set_input_as_handled()
	elif index == _interact_touch_index:
		_release_interact()
		get_viewport().set_input_as_handled()

func _update_joystick(pos: Vector2) -> void:
	var delta := pos - _joy_center
	var mag := minf(delta.length(), _joy_radius)
	var dir := delta.normalized() if delta.length() > 0.001 else Vector2.ZERO
	_joy_knob.position = (_joy_base.size - _joy_knob.size) / 2.0 + dir * mag
	var strength := dir * (mag / _joy_radius)
	_set_axis("right", maxf(strength.x, 0.0))
	_set_axis("left", maxf(-strength.x, 0.0))
	_set_axis("down", maxf(strength.y, 0.0))
	_set_axis("up", maxf(-strength.y, 0.0))

func _set_axis(key: String, strength: float) -> void:
	var action: String = MOVE_ACTIONS[key]
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)

func _release_joystick() -> void:
	_joy_touch_index = -1
	_center_knob()
	for action in MOVE_ACTIONS.values():
		Input.action_release(action)

func _press_interact() -> void:
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	Input.parse_input_event(ev)

func _release_interact() -> void:
	if _interact_touch_index == -1 and not Input.is_action_pressed("interact"):
		return
	_interact_touch_index = -1
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = false
	Input.parse_input_event(ev)
