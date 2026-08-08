extends SceneTree

## Terminal entry point for WorldMapBaker, for re-baking without opening the
## editor:
##
##   cd apps/game && godot --script scripts/tools/bake_world_map_cli.gd
##
## Needs a real display - --headless uses the dummy renderer and bakes black.
## Godot has to reimport the new PNGs afterwards, which happens the next time the
## editor opens the project (or on `godot --headless --import`).

var _started := false

# Not _initialize(): the tree is not live yet there (root.get_tree() is still
# null), so nodes added never enter it and Camera2D.make_current() silently
# no-ops, which bakes the world's top-left corner at 1:1. By the first frame the
# tree is up. Returning false leaves SceneTree's own processing alone.
func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_bake()
	return false

func _bake() -> void:
	var count: int = await WorldMapBaker.bake_all(root)
	print("[bake_world_map_cli] done - baked %d world(s)" % count)
	quit(0 if count > 0 else 1)
