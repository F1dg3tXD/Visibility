extends Node3D

@onready var animation_player: AnimationPlayer = _find_animation_player()

func _find_animation_player() -> AnimationPlayer:
	for n in find_children("*", "AnimationPlayer", true, false):
		if n is AnimationPlayer:
			return n
	return null

@export var locked: bool = false

var _is_open: bool = false
var _transitioning: bool = false

func _ready() -> void:
	# Hook up any child interaction volume.
	for child in get_children():
		if child is Area3D and child.has_signal("interacted"):
			child.interacted.connect(interact)
	animation_player.play("idle")

func interact() -> void:
	if animation_player == null:
		push_warning("No AnimationPlayer found")
		return
	if _transitioning or animation_player.is_playing():
		return
	_transitioning = true
	if locked:
		animation_player.play("locked")
	elif not _is_open:
		animation_player.play("open")
		_is_open = true
	else:
		animation_player.play("idle")
		_is_open = false
	# Wait for animation to finish before allowing another interaction.
	await animation_player.animation_finished
	_transitioning = false

func lock() -> void:
	locked = true

func unlock() -> void:
	locked = false


func _on_interaction_volume_interact_pressed() -> void:
	interact()


func _on_interaction_volume_interacted() -> void:
	interact()
