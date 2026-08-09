@tool
extends EditorScript

## Editor entry point for WorldMapBaker - open this file in the script editor and
## hit File > Run (Ctrl+Shift+X). See scripts/tools/world_map_baker.gd for what it
## actually does and where the output lands.

func _run() -> void:
	var count: int = await WorldMapBaker.bake_all(EditorInterface.get_base_control())
	if count == 0:
		return
	# Without a rescan the new PNGs have no .import file, so load() fails at
	# runtime even though the files are sitting right there.
	EditorInterface.get_resource_filesystem().scan()
	print("[bake_world_map] done - baked %d world(s)" % count)
