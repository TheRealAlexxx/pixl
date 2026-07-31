extends "res://scripts/multiplayer_world.gd"

# New Day-0 arrival flow (cinematic → Pixo greeting → naming → experience →
# first Trial). Launched here on first arrival; the F1 manual (GuideHud) is
# separate.
const ONBOARDING := preload("res://scripts/onboarding.gd")

var can_transition: bool = false
var _npcs: Array = []
var _npcs_by_id: Dictionary = {}
var _save_accum: float = 0.0

func _ready() -> void:
	super._ready()
	_spawn_npcs()
	if NetworkManager.is_connected_to_server():
		NetworkManager.npc_init.connect(_on_npc_init)
	_reveal_trial_npcs()
	await get_tree().create_timer(0.3).timeout
	can_transition = true
	_maybe_start_arrival()

# A Trial-giver's check-in copy (e.g. Ridit) is hidden until the player has
# accepted that Trial and not yet finished it. Reveal on load by matching each
# check-in NPC's trial_name against the player's active Trials.
func _reveal_trial_npcs() -> void:
	var checkins: Array = _npcs.filter(func(n): return is_instance_valid(n) and n.get("trial_checkin") == true)
	if checkins.is_empty() or NetworkManager.session_token == "":
		return
	var req := HTTPRequest.new()
	add_child(req)
	var url := NetworkManager.SERVER_HTTP_URL + "/api/sidequests?token=" + NetworkManager.session_token.uri_encode()
	req.request_completed.connect(func(_result, code, _headers, data):
		req.queue_free()
		var active := {}  # trial name -> true when unlocked and not completed
		if code == 200 and data.size() > 0:
			var json = JSON.parse_string(data.get_string_from_utf8())
			if typeof(json) == TYPE_DICTIONARY and json.get("ok", false):
				for q in json.get("quests", []):
					if typeof(q) == TYPE_DICTIONARY and bool(q.get("unlocked", false)) and not bool(q.get("completed", false)):
						active[String(q.get("name", ""))] = true
		for n in checkins:
			if is_instance_valid(n):
				n.set_present(active.has(String(n.get("trial_name"))))
	)
	if req.request(url) != OK:
		req.queue_free()

# Decide whether to run the first-run arrival flow. Signed-in players are gated
# on the server's shared onboarding counter (step 0 = never onboarded), so a
# server-side reset re-triggers it. Signed-out / offline dev falls back to the
# old once-per-device slide-deck guide.
func _maybe_start_arrival() -> void:
	if NetworkManager.session_token == "":
		GuideHud.maybe_show_intro()
		return
	GuideHud.fetch_onboarding_step(func(step):
		# The step check is an HTTP round-trip; the player may have left the
		# village (Quit to Main Menu) before it lands. Don't start the flow onto
		# a scene we're no longer in.
		if step == 0 and is_inside_tree() and get_tree().current_scene == self:
			_start_arrival()
	)

func _start_arrival() -> void:
	var flow := ONBOARDING.new()
	add_child(flow)
	flow.finished.connect(func(): flow.queue_free())
	flow.start()

func _exit_tree() -> void:
	_save_npcs()

func _spawn_npcs() -> void:
	for child in get_children():
		if child.has_method("npc_id"):
			_npcs.append(child)
			_npcs_by_id[child.npc_id()] = child

func _on_npc_init(scene: String, npcs: Array) -> void:
	if scene != _network_scene_name():
		return
	for saved in npcs:
		var n = _npcs_by_id.get(saved["id"])
		if n:
			n.apply_saved_position(saved["pos"])

func _save_npcs() -> void:
	if not NetworkManager.is_connected_to_server():
		return
	var payload: Array = []
	for n in _npcs:
		# Skip hidden conditional NPCs (a not-yet-revealed check-in copy) so we
		# don't persist a placeholder position for them.
		if is_instance_valid(n) and n.visible:
			payload.append({"id": n.npc_id(), "posX": n.position.x, "posY": n.position.y})
	NetworkManager.send_save_npcs(_network_scene_name(), payload)

func _process(delta: float) -> void:
	_save_accum += delta
	if _save_accum >= 5.0:
		_save_accum = 0.0
		_save_npcs()
	if global.player_in_range and can_transition and not Dialogue.is_open and not global.ui_blocked() and Input.is_action_just_pressed("interact"):
		if global.active_door_target == "shop":
			WebPages.open("shop")
			return
		can_transition = false
		_save_npcs()
		var door := Vector2i(global.active_door_pos.round())
		global.house_variant = absi(door.x * 928371 + door.y * 1237) % 4
		global.request_transition("house_interior", "PlayerSpawn")
		Loader.change_scene("res://scenes/house_interior.tscn", "Loading")
