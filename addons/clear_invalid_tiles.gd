@tool
extends EditorScript

func _run():
	var selection = get_editor_interface().get_selection()

	for layer_node in selection.get_selected_nodes():
		if layer_node is TileMapLayer:
			print("🧹 Cleaning TileMapLayer: ", layer_node.name)

			var tileset = layer_node.tile_set
			if tileset == null:
				print("⚠️ Skipping layer with no TileSet assigned: ", layer_node.name)
				continue

			var used_cells = layer_node.get_used_cells()

			for cell in used_cells:
				var source_id = layer_node.get_cell_source_id(cell)  # ✅ Correct API
				if not tileset.has_source(source_id):
					layer_node.erase_cell(cell)
					print(" - Erased invalid tile at: ", cell)

			print("✅ Done cleaning invalid tiles on: ", layer_node.name)
		else:
			print("⚠️ Skipping non-TileMapLayer node: ", layer_node)
