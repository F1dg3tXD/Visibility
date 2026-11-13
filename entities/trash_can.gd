extends Node3D

@export var keyScene: PackedScene
@onready var key_spawn: Marker3D = $keySpawn

var has_spawned_key: bool = false


func _on_trash_interact_body_entered(body: Node3D) -> void:
	if not body is ToiletPaper:
		return
	# Add time to the player's shit meter.
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var shit_meter = player.get_node_or_null("shitMeter")
		if shit_meter and shit_meter.has_method("add_time"):
			shit_meter.add_time(body.timerAdd)
	# Spawn key.
	if keyScene:
		var key = keyScene.instantiate()
		get_tree().current_scene.add_child(key)
		if key is Node3D:
			key.global_position = key_spawn.global_position
	# Remove toilet paper.
	body.queue_free()
