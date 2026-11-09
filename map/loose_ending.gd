extends Node3D

@onready var ending_trigger: Area3D = $EndingTrigger
@onready var level_music: AudioStreamPlayer = %LevelMusic
@onready var ending_screen: Control = $"../Player_pawn/EndingScreen"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ending_trigger.visible = false
	ending_trigger.monitoring = false
	ending_trigger.monitorable = true
	ending_trigger.collision_layer = 1
	ending_trigger.collision_mask = 1

func end_trigger()-> void:
	ending_screen.set_ending_volume(0.0)
	level_music.stop()
	ending_trigger.visible = true
	ending_trigger.monitoring = true

func _on_shit_meter_time_ended() -> void:
	end_trigger()
