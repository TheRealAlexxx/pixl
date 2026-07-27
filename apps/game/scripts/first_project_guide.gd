extends CanvasLayer
## First-Project Guide — a persistent, NON-blocking checklist that walks a brand-
## new Builder from "no project yet" all the way to their first ship, one step at
## a time: create the project → set up Hackatime → build it → ship it.
##
## Opt-in: onboarding.gd calls begin() only when a beginner says yes. From then on
## the guide lives across scenes and sessions, tracks real progress by polling the
## server (projects + Hackatime), checks steps off as they land, and pops a short
## Pixo line at each milestone. It never pushes a UI blocker — the player can walk,
## chat and tab out to the browser the whole time.

const THEME := preload("res://themes/main_theme.tres")
const GAMEPLAY_SCENES := ["village", "open_world", "house_interior", "shop_interior"]
const SAVE_PATH := "user://first_project_guide.cfg"
const POLL_INTERVAL := 12.0
const ACCENT_GOLD := Color(0.85098, 0.643137, 0.25098)
const DIM := Color(0.62, 0.57, 0.47)
const PIXO := "Pixo"

# The four steps, in order. Each carries its checklist label, the button copy for
# when it's the current step, the companion page that button opens, and the line
# Pixo says once it's completed.
enum { S_CREATE, S_HACKATIME, S_CODE, S_SHIP, S_DONE }
const STEP_LABELS := [
	"Create your project",
	"Set up Hackatime",
	"Build it",
	"Ship your first project",
]
const STEP_ACTIONS := [
	"Open Builder Terminal",
	"Hackatime setup",
	"Open the build guide",
	"Ship it for review",
]
const STEP_PAGES := ["projects", "docs/hackatime", "docs/first-site", "projects"]
const STEP_HINT := [
	"Name your first project in the Builder Terminal — that tells the Core you're building.",
	"Install Hackatime in your editor and connect it, so the hours you code actually count.",
	"Make the thing. Keep it small and real — the guide has copy-pasteable code to start from.",
	"Once it runs and you've logged some time, ship it for review to finish your first Trial.",
]
const STEP_DONE_LINE := [
	"Project created — the Core can see it now. Next: get Hackatime tracking your hours so they count.",
	"Hackatime's live. Every minute you code from here on counts. Go make the thing.",
	"There it is — your first tracked time. Keep going until it's real, then ship it.",
	"You shipped it. Your first project is in the Restoration — that's the whole game. Welcome, Builder.",
]

var _active := false
var _step := S_CREATE
var _collapsed := false
var _busy := false

var _root: Control
var _body: VBoxContainer
var _rows: Array = []          # Array[Label]
var _hint: Label
var _action_btn: Button
var _collapse_btn: Button
var _timer: Timer

func _ready() -> void:
	layer = 106
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_timer = Timer.new()
	_timer.wait_time = POLL_INTERVAL
	_timer.timeout.connect(_on_tick)
	add_child(_timer)
	_load_state()
	if _active:
		_render()
		_timer.start()
		_poll()

# ── public ───────────────────────────────────────────────────────────────────

## Start (or restart) the guide — called from the beginner onboarding opt-in.
func begin() -> void:
	_active = true
	_step = S_CREATE
	_collapsed = false
	_save_state(true)
	_render()
	_timer.start()
	_poll()

# ── lifecycle / visibility ───────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if not _active:
		if _root.visible:
			_root.visible = false
		return
	_root.visible = _in_gameplay() and NetworkManager.session_token != ""

func _in_gameplay() -> bool:
	var cur := get_tree().current_scene
	return cur != null and GAMEPLAY_SCENES.has(cur.scene_file_path.get_file().get_basename())

func _on_tick() -> void:
	if _active and _in_gameplay() and NetworkManager.session_token != "":
		_poll()

# ── polling / state machine ──────────────────────────────────────────────────

func _poll() -> void:
	if _busy or not _active or NetworkManager.session_token == "":
		return
	_busy = true
	var proj: Dictionary = await _api_get("/api/projects")
	var hack: Dictionary = await _api_get("/api/hackatime/stats")
	_busy = false
	if not _active:
		return

	var projects: Array = proj.get("projects", []) if typeof(proj.get("projects")) == TYPE_ARRAY else []
	var stats: Dictionary = hack.get("stats", {}) if typeof(hack.get("stats")) == TYPE_DICTIONARY else {}
	var has_project := projects.size() > 0
	var connected := bool(stats.get("connected", false))
	var total_seconds := float(stats.get("totalSeconds", 0))
	var shipped := false
	for p in projects:
		var st := String(p.get("status", ""))
		if st == "shipped" or st == "second_review" or st == "approved":
			shipped = true
			break

	# Current step = the first one that isn't satisfied yet.
	var new_step := S_DONE
	if not has_project:
		new_step = S_CREATE
	elif not connected:
		new_step = S_HACKATIME
	elif total_seconds <= 0.0:
		new_step = S_CODE
	elif not shipped:
		new_step = S_SHIP
	_apply_step(new_step)

func _apply_step(new_step: int) -> void:
	if new_step == _step:
		return
	if new_step > _step:
		# Announce the most recent completion (index new_step - 1), and if we blew
		# past the last step, close it out.
		var completed := new_step - 1
		if completed >= 0 and completed < STEP_DONE_LINE.size():
			_say(STEP_DONE_LINE[completed])
	_step = new_step
	if _step == S_DONE:
		_timer.stop()
		_save_state(false)  # don't auto-resume next session; stays visible until closed
	else:
		_save_state(true)
	_render()

# ── UI ───────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = THEME
	_root.visible = false
	add_child(_root)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_right = 0.0
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_END
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.offset_left = 18
	panel.custom_minimum_size = Vector2(300, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	# Header: title + collapse toggle.
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	col.add_child(header)

	var title := Label.new()
	title.text = "YOUR FIRST PROJECT"
	title.theme_type_variation = &"TitleText"
	title.add_theme_font_size_override("font_size", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_collapse_btn = Button.new()
	_collapse_btn.theme_type_variation = &"GreyButton"
	_collapse_btn.custom_minimum_size = Vector2(30, 0)
	_collapse_btn.pressed.connect(_toggle_collapse)
	header.add_child(_collapse_btn)

	# Body: the checklist, current-step hint, and the action button.
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 8)
	col.add_child(_body)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 5)
	_body.add_child(list)
	for i in STEP_LABELS.size():
		var row := Label.new()
		row.add_theme_font_size_override("font_size", 16)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(row)
		_rows.append(row)

	_hint = Label.new()
	_hint.theme_type_variation = &"InfoText"
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(_hint)

	_action_btn = Button.new()
	_action_btn.add_theme_font_size_override("font_size", 16)
	_action_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_btn.pressed.connect(_on_action)
	_body.add_child(_action_btn)

func _render() -> void:
	_collapse_btn.text = "+" if _collapsed else "–"  # + when hidden, en-dash when open
	_body.visible = not _collapsed

	for i in _rows.size():
		var label: Label = _rows[i]
		if i < _step:
			label.text = "[x] " + STEP_LABELS[i]
			label.add_theme_color_override("font_color", ACCENT_GOLD)
		elif i == _step:
			label.text = "[>] " + STEP_LABELS[i]
			label.add_theme_color_override("font_color", Color(1, 1, 1))
		else:
			label.text = "[ ] " + STEP_LABELS[i]
			label.add_theme_color_override("font_color", DIM)

	if _step == S_DONE:
		_hint.text = "All done. Your first project is shipped — the rest of Pixl is the same loop."
		_action_btn.text = "Close"
	else:
		_hint.text = STEP_HINT[_step]
		_action_btn.text = STEP_ACTIONS[_step]

func _toggle_collapse() -> void:
	_collapsed = not _collapsed
	_render()

func _on_action() -> void:
	if _step == S_DONE:
		_active = false
		_root.visible = false
		return
	WebPages.open(STEP_PAGES[_step])

func _say(line: String) -> void:
	# Non-blocking nudge — Dialogue doesn't freeze movement, and we don't await it.
	if line == "":
		return
	Dialogue.open(PIXO, [line])

# ── persistence ──────────────────────────────────────────────────────────────

func _save_state(active: bool) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({ "active": active, "step": _step }))
		f.close()

func _load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return
	_active = bool(data.get("active", false))
	_step = int(data.get("step", S_CREATE))

# ── net ──────────────────────────────────────────────────────────────────────

func _api_get(path: String) -> Dictionary:
	if NetworkManager.session_token == "":
		return {}
	var req := HTTPRequest.new()
	add_child(req)
	var url := NetworkManager.SERVER_HTTP_URL + path
	url += ("&" if path.contains("?") else "?") + "token=" + NetworkManager.session_token.uri_encode()
	req.request(url, PackedStringArray(), HTTPClient.METHOD_GET)
	var r: Array = await req.request_completed
	req.queue_free()
	if int(r[1]) != 200 or (r[3] as PackedByteArray).size() == 0:
		return {}
	var json = JSON.parse_string((r[3] as PackedByteArray).get_string_from_utf8())
	return json if typeof(json) == TYPE_DICTIONARY else {}
