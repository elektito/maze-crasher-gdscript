extends Node2D

func _input(event):
	if OS.is_debug_build() and Input.is_action_just_pressed("debug"):
		$maze.set_debug_mode(not $maze.debug_mode)
	
	if Input.is_action_just_pressed("rebuild"):
		$maze.rebuild_maze()
