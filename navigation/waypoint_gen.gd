extends Node2D
class_name CorridorWaypointGenerator

@export var tilemap: TileMapLayer
@export var navigation_layer_bit: int = 0  # Bit 0 corresponds to navigation layer 1
@export var waypoint_spacing: int = 3  # Space between waypoints in tiles
@export var generate_waypoints: bool = false:
	set(value):
		if value and tilemap:
			clear_existing_waypoints()
			generate_corridor_waypoints()
			generate_waypoints = false

@export var clear_waypoints: bool = false:
	set(value):
		if value:
			clear_existing_waypoints()
			clear_waypoints = false

@export_group("Visual Settings")
@export var waypoint_color: Color = Color.RED
@export var connection_color: Color = Color.BLUE
@export var waypoint_size: float = 10.0
@export var connection_width: float = 2.0

# Clear all existing waypoints
func clear_existing_waypoints():
	for child in tilemap.get_children():
		if child.name.begins_with("Waypoint_"):
			child.queue_free()

# Generate waypoints for corridors
func generate_corridor_waypoints():
	var walkable_cells = get_walkable_cells()
	var special_cells = classify_cells(walkable_cells)
	var corridor_cells = special_cells["corridor"]
	var junction_cells = special_cells["junction"]
	var endpoint_cells = special_cells["endpoint"]
	
	# Create paths between junctions and endpoints
	var paths = create_paths_optimized(corridor_cells, junction_cells, endpoint_cells)
	
	# Place waypoints along the paths
	place_waypoints_along_paths(paths)

# Get walkable cells from the navigation layer
func get_walkable_cells() -> Array:
	var walkable_cells = []
	var used_cells = tilemap.get_used_cells()
	
	for cell in used_cells:
		var tile_data = tilemap.get_cell_tile_data(cell)  # Using layer 0 for tile data
		if tile_data and tile_data.get_navigation_polygon(navigation_layer_bit) != null:
			walkable_cells.append(cell)
	
	return walkable_cells

# Classify the walkable cells into corridor, junction, and endpoint
func classify_cells(walkable_cells: Array) -> Dictionary:
	var result = {
		"corridor": [],
		"junction": [],
		"endpoint": []
	}
	
	var directions = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	var walkable_dict = {}
	
	for cell in walkable_cells:
		walkable_dict[cell] = true
	
	for cell in walkable_cells:
		var neighbors = 0
		for dir in directions:
			if walkable_dict.has(cell + dir):
				neighbors += 1
		
		if neighbors == 1:
			result["endpoint"].append(cell)
		elif neighbors == 2:
			result["corridor"].append(cell)
		elif neighbors > 2:
			result["junction"].append(cell)
	
	return result

# Create optimized paths from corridor, junction, and endpoint cells
func create_paths_optimized(corridor_cells: Array, junction_cells: Array, endpoint_cells: Array) -> Array:
	var paths = []
	var all_special_cells = junction_cells + endpoint_cells
	
	var corridor_dict = {}
	for cell in corridor_cells:
		corridor_dict[cell] = true
		
	var special_dict = {}
	for cell in all_special_cells:
		special_dict[cell] = true
	
	var processed_dict = {}
	var directions = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	
	for start_cell in all_special_cells:
		for dir in directions:
			var current_cell = start_cell + dir
			
			if not corridor_dict.has(current_cell) or processed_dict.has(current_cell):
				continue
				
			var path = [start_cell]
			processed_dict[current_cell] = true
			path.append(current_cell)
			
			var prev_cell = start_cell
			var continue_path = true
			
			while continue_path:
				continue_path = false
				
				for next_dir in directions:
					var candidate = current_cell + next_dir
					
					if candidate == prev_cell:
						continue
						
					if special_dict.has(candidate):
						path.append(candidate)
						paths.append(path)
						continue_path = false
						break
						
					elif corridor_dict.has(candidate) and not processed_dict.has(candidate):
						processed_dict[candidate] = true
						path.append(candidate)
						prev_cell = current_cell
						current_cell = candidate
						continue_path = true
						break
				
				if not continue_path and path.size() > 1:
					paths.append(path)
	
	return paths

# Place waypoints along paths
func place_waypoints_along_paths(paths: Array):
	var waypoint_dict = {}
	var waypoint_index = 0
	
	for path in paths:
		if path.size() < 2:
			continue
		
		var start_pos = tilemap.map_to_local(path[0])
		var end_pos = tilemap.map_to_local(path[path.size() - 1])
		
		create_waypoint_node(start_pos, waypoint_index)
		waypoint_index += 1
		
		for i in range(1, path.size() - 1, waypoint_spacing):
			var pos = tilemap.map_to_local(path[i])
			create_waypoint_node(pos, waypoint_index)
			waypoint_index += 1
		
		create_waypoint_node(end_pos, waypoint_index)
		waypoint_index += 1

# Create and add a waypoint node to the TileMapLayer
func create_waypoint_node(pos: Vector2, index: int):
	var rounded_pos = Vector2(round(pos.x), round(pos.y))
	
	# Check for existing waypoints to avoid duplicates
	for child in tilemap.get_children():
		if child.name.begins_with("Waypoint_") and child.position.distance_to(rounded_pos) < 10:
			return
	
	var waypoint = Node2D.new()
	waypoint.name = "Waypoint_" + str(index)
	waypoint.position = rounded_pos
	waypoint.set_meta("waypoint_index", index)
	
	# Add the waypoint node as a child of the TileMapLayer
	tilemap.add_child(waypoint)
	
	# Ensure the node appears in the editor if it's in the editor
	if Engine.is_editor_hint():
		waypoint.owner = get_tree().edited_scene_root

# Connect waypoints in-game (not in the editor)
func connect_waypoints_at_runtime():
	var waypoint_nodes = []
	
	for child in tilemap.get_children():
		if child.name.begins_with("Waypoint_"):
			waypoint_nodes.append(child)
	
	var max_connection_distance = 200.0
	
	for i in range(waypoint_nodes.size()):
		for j in range(i + 1, waypoint_nodes.size()):
			var wp1 = waypoint_nodes[i]
			var wp2 = waypoint_nodes[j]
			
			var distance = wp1.position.distance_to(wp2.position)
			if distance <= max_connection_distance:
				pass  # You can store or draw the connections here

# Get all waypoint nodes
func get_waypoint_nodes() -> Array:
	var waypoint_nodes = []
	for child in tilemap.get_children():
		if child.name.begins_with("Waypoint_"):
			waypoint_nodes.append(child)
	return waypoint_nodes

# Editor visualization (waypoints and connections)
func _draw():
	if not Engine.is_editor_hint() or not tilemap:
		return
	
	var waypoint_nodes = get_waypoint_nodes()
	
	# Draw waypoints as circles
	for wp in waypoint_nodes:
		draw_circle(wp.position - global_position, waypoint_size, waypoint_color)
	
	var max_connection_distance = 200.0
	for i in range(waypoint_nodes.size()):
		for j in range(i + 1, waypoint_nodes.size()):
			var wp1 = waypoint_nodes[i]
			var wp2 = waypoint_nodes[j]
			
			if wp1.position.distance_to(wp2.position) <= max_connection_distance:
				draw_line(wp1.position - global_position, wp2.position - global_position, 
						  connection_color, connection_width)
