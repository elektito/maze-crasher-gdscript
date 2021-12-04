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
	$light_main.visible = not $light_main.visible
	$light_aux.visible = not $light_aux.visible
	$light_player.visible = not $light_player.visible
