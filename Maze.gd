extends Node2D

export(int) var rows := 18 setget set_rows
export(int) var cols := 31 setget set_cols
export(bool) var debug_mode := false setget set_debug_mode
export(bool) var slow_gen_mode := false setget set_slow_gen_mode

var size: Vector2 setget set_size, get_size

var maze := []
var camera_original_zoom := Vector2.ZERO
var stack := []

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
		return '<' + str(row) + ',' + str(col) + '>'


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


func get_connected_neighbors(cell):
	var neighbors := []
	
	var top = cell_at(cell.row - 1, cell.col)
	if not cell.top_wall and top != null:
		neighbors.append(top)
	
	var bottom = cell_at(cell.row + 1, cell.col)
	if not cell.bottom_wall and bottom != null:
		neighbors.append(bottom)
	
	var left = cell_at(cell.row, cell.col - 1)
	if not cell.left_wall and left != null:
		neighbors.append(left)
	
	var right = cell_at(cell.row, cell.col + 1)
	if not cell.right_wall and right != null:
		neighbors.append(right)
	
	return neighbors


func cell_index(cell):
	return cell.row * cols + cell.col


func cell_at(row: int, col: int):
	if row < 0 or row >= rows or col < 0 or col >= cols:
		return null
	var idx := row * cols + col
	return maze[idx]


func _ready():
	randomize()
	rebuild_maze()
	
	var q := []
	var source = cell_at(0, 0)
	var dist := {}
	var prev := {}
	for cell in maze:
		dist[cell] = INF
		prev[cell] = null
		q.append(cell)
	dist[source] = 0
	while q != []:
		var u = null
		for v in q:
			if u == null or dist[v] < dist[u]:
				u = v
		q.erase(u)
		
		for v in get_connected_neighbors(u):
			if not v in q:
				continue
			var alt = dist[u] + 1
			if alt < dist[v]:
				dist[v] = alt
				prev[v] = u
	
	var maxv = null
	for v in maze:
		if maxv == null or dist[v] > dist[maxv]:
			maxv = v
	print('maxv: ', maxv, ' ', dist[maxv])
	var cur = maxv
	var path := []
	while cur in prev:
		path.append(cur)
		cur = prev[cur]
	path.invert()
	print('path to maxv: ', path)
	
	var line := Line2D.new()
	line.modulate = Color.red
	line.width = 2
	var cellsize := 32
	for cell in path:
		var cell_pos := Vector2(cell.col * cellsize + cellsize / 2, cell.row * cellsize + cellsize / 2)
		line.add_point(cell_pos)
	add_child(line)
	
	return
	print('dist:')
	for k in dist.keys():
		print('   ', k, ': ', dist[k])
	print('prev:')
	for k in prev.keys():
		print('   ', k, ': ', prev[k])


func rebuild_maze():
	$player/camera.limit_right = cols * $maze_map.cell_size.x
	$player/camera.limit_bottom = rows * $maze_map.cell_size.y
	
	maze = []
	for row in range(rows):
		for col in range(cols):
			maze.append(Cell.new(row, col))
	
	$bg.rect_size = $maze_map.cell_size * Vector2(cols, rows)
	
	var start_cell = cell_at(0, 0)
	start_cell.visited = true
	stack.append(start_cell)
	
	if not slow_gen_mode:
		while stack:
			maze_step()
		
		generate_map_from_maze()
	else:
		$cur_cell_indicator.visible = true
		$slow_gen_timer.start()


func maze_step(rebuild_map=false):
	var cell = stack.pop_back()
	if cell == null:
		return
	#print('>>>> ', cell)
	$cur_cell_indicator.rect_position.x = cell.col * $maze_map.cell_size.x
	$cur_cell_indicator.rect_position.y = cell.row * $maze_map.cell_size.y
	$cur_cell_indicator.rect_size = $maze_map.cell_size
	cell.visited = true
	var unvisited_neighbors = get_unvisited_neighbors(cell)
	if unvisited_neighbors:
		stack.push_back(cell)
		var next = unvisited_neighbors[randi() % len(unvisited_neighbors)]
		connect_cells(cell, next)
		next.visited = true
		stack.push_back(next)
	
	if rebuild_map:
		generate_map_from_maze()


func generate_map_from_maze():
	$maze_map.clear()
	for row in range(rows):
		for col in range(cols):
			var cell = cell_at(row, col)
			var tile_name = cell.get_tile_name()
			var tile = $maze_map.tile_set.find_tile_by_name(tile_name)
			$maze_map.set_cell(col, row, tile)


func set_size(value: Vector2):
	pass # not settable


func get_size() -> Vector2:
	return $bg.rect_size


func set_rows(value: int):
	rows = value
	rebuild_maze()


func set_cols(value: int):
	cols = value
	rebuild_maze()


func set_debug_mode(value: bool):
	if not OS.is_debug_build():
		return
	
	debug_mode = value
	if debug_mode:
		camera_original_zoom = $player/camera.zoom
	else:
		$player/camera.zoom = camera_original_zoom
	$canvas_modulate.visible = not debug_mode
	$player.enable_lights(not debug_mode)


func set_slow_gen_mode(value: bool):
	slow_gen_mode = value


func _on_slow_gen_timer_timeout():
	maze_step(true)


func _input(event):
	var zoom_step = Vector2(0.1, 0.1)
	if debug_mode and event is InputEventMouseButton and event.button_index == BUTTON_WHEEL_UP and event.is_pressed():
		if $player/camera.zoom > zoom_step:
			$player/camera.zoom -= zoom_step
	if debug_mode and event is InputEventMouseButton and event.button_index == BUTTON_WHEEL_DOWN and event.is_pressed():
		$player/camera.zoom += zoom_step
