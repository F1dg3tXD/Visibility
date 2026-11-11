extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _on_new_game_button_pressed() -> void:
	animation_player.play("Door_open")
