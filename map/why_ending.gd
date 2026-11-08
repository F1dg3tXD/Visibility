extends Node3D

@onready var ending_trigger: Area3D = $EndingTrigger

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ending_trigger.visible = true
	ending_trigger.monitoring = true
	ending_trigger.monitorable = true
	ending_trigger.collision_layer = 1
	ending_trigger.collision_mask = 1

func end_trigger()-> void:
	ending_trigger.visible = true

func _on_interaction_volume_interact_pressed() -> void:
	end_trigger()
