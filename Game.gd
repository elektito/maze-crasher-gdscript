extends Node2D

var rows := 18
var cols := 31
var maze := []

var debug_mode := false
var camera_original_zoom := Vector2.ZERO

class Cell:
	var row: int
	var col: int
	
	var visited := false
	
	var top_wall: bool = true
	var right_wall: bool = true
	var bottom_wall: bool = true
	var left_wall: bool = true
	
	func _init(row: int, col: int):
		self.row = row
		self.col = col
	
	func get_tile_name() -> String:
		var tile_name := ''
		if top_wall:
			tile_name += 'top-'
		if right_wall:
			tile_name += 'right-'
		if bottom_wall:
			tile_name += 'bottom-'
		if left_wall:
			tile_name += 'left-'
		if tile_name == '':
			tile_name = 'empty'
		else:
			tile_name = tile_name.substr(0, len(tile_name) - 1)
		return tile_name
	
	func _to_string():
		return str(row) + ',' + str(col)


func connect_cells(cell1, cell2):
	#print('connecting ', cell1, ' and ', cell2)
	if cell1.col == cell2.col + 1:
		cell1.left_wall = false
		cell2.right_wall = false
	elif cell2.col == cell1.col + 1:
		cell1.right_wall = false
		cell2.left_wall = false
	elif cell1.row == cell2.row + 1:
		cell1.top_wall = false
		cell2.bottom_wall = false
	elif cell2.row == cell1.row + 1:
		cell1.bottom_wall = false
		cell2.top_wall = false
	else:
		print('cells (', cell1.row, ',', cell1.row, ' and ', cell2.row, ',', cell2.col, ') are not neighbors; cant connect.')


func get_unvisited_neighbors(cell):
	var neighbor
	var neighbors := []
	
	neighbor = cell_at(cell.row + 1, cell.col)
	if neighbor and not neighbor.visited:
		neighbors.append(neighbor)
	
	neighbor = cell_at(cell.row - 1, cell.col)
	if neighbor and not neighbor.visited:
		neighbors.append(neighbor)
	
	neighbor = cell_at(cell.row, cell.col + 1)
	if neighbor and not neighbor.visited:
		neighbors.append(neighbor)
	
	neighbor = cell_at(cell.row, cell.col - 1)
	if neighbor and not neighbor.visited:
		neighbors.append(neighbor)
	
	return neighbors


func cell_index(cell):
	return cell.row * cols + cell.col


func cell_at(row: int, col: int):
	if row < 0 or row >= rows or col < 0 or col >= cols:
		return null
	var idx := row * cols + col
	return maze[idx]


var stack := []
func _ready():
	randomize()
	
	for row in range(rows):
		for col in range(cols):
			maze.append(Cell.new(row, col))
	
	#var stack := []
	var start_cell = cell_at(0, 0)
	start_cell.visited = true
	stack.append(start_cell)
	
	#return
	while stack:
		var cell = stack.pop_back()
		cell.visited = true
		var unvisited_neighbors = get_unvisited_neighbors(cell)
		if unvisited_neighbors:
			stack.push_back(cell)
			var next = unvisited_neighbors[randi() % len(unvisited_neighbors)]
			connect_cells(cell, next)
			next.visited = true
			stack.push_back(next)
	
	generate_map_from_maze()


func maze_step():
	return
	var cell = stack.pop_back()
	if cell == null:
		return
	#print('>>>> ', cell)
	$ColorRect.rect_position.x = cell.col * $maze_map.cell_size.x
	$ColorRect.rect_position.y = cell.row * $maze_map.cell_size.y
	$ColorRect.rect_size = $maze_map.cell_size
	cell.visited = true
	var unvisited_neighbors = get_unvisited_neighbors(cell)
	if unvisited_neighbors:
		stack.push_back(cell)
		var next = unvisited_neighbors[randi() % len(unvisited_neighbors)]
		connect_cells(cell, next)
		next.visited = true
		stack.push_back(next)
	
	generate_map_from_maze()


func generate_map_from_maze():
	for row in range(rows):
		for col in range(cols):
			var cell = cell_at(row, col)
			var tile_name = cell.get_tile_name()
			var tile = $maze_map.tile_set.find_tile_by_name(tile_name)
			$maze_map.set_cell(col, row, tile)


func _on_Timer_timeout():
	maze_step()


func _input(event):
	if OS.is_debug_build() and Input.is_action_just_pressed("debug"):
		debug_mode = not debug_mode
		if not debug_mode:
			$player/camera.zoom = camera_original_zoom
		$canvas_modulate.visible = not $canvas_modulate.visible
		$player.toggle_lights()
		camera_original_zoom = $player/camera.zoom
	
	var zoom_step = Vector2(0.1, 0.1)
	if debug_mode and event is InputEventMouseButton and event.button_index == BUTTON_WHEEL_UP and event.is_pressed():
		$player/camera.zoom += zoom_step
	if debug_mode and event is InputEventMouseButton and event.button_index == BUTTON_WHEEL_DOWN and event.is_pressed():
		if $player/camera.zoom > zoom_step:
			$player/camera.zoom -= zoom_step
