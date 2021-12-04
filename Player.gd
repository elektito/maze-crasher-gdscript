extends KinematicBody2D

var velocity := Vector2.ZERO
onready var camera := $camera

func _input(event):
	var dir = Vector2.ZERO
	if Input.is_action_pressed("up"):
		dir += Vector2.UP
	if Input.is_action_pressed("left"):
		dir += Vector2.LEFT
	if Input.is_action_pressed("down"):
		dir += Vector2.DOWN
	if Input.is_action_pressed("right"):
		dir += Vector2.RIGHT
	velocity = dir * 150.0


func _physics_process(delta):
	velocity = move_and_slide(velocity)


func toggle_lights():
	enable_lights(not $light_main.visible)


func enable_lights(value: bool):
	$light_main.visible = value
	$light_aux.visible = value
	$light_player.visible = value
