extends Node3D

@onready var animation_tree: AnimationTree = $AnimationTree

@export var locked: bool = false
@export var is_open: bool = false
@onready var audio: AudioStreamPlayer3D = $audio
const lock_sound = preload("res://sfx/dragon-studio-locking-door-454241.ogg")
const door_sound = preload("res://sfx/dragon-studio-door-closed-382707.ogg")


func _ready() -> void:
	if animation_tree:
		animation_tree.active = true
		animation_tree.set("parameters/StateMachine/conditions/is_open", is_open)
		animation_tree.set("parameters/StateMachine/conditions/is_closed", not is_open)
		animation_tree.set("parameters/Locked/active", 0)

func interact() -> void:
	if not animation_tree:
		return
	if locked:
		animation_tree.set("parameters/Locked/request", 1)
		audio.stream = lock_sound
		audio.play()
		return
	# Toggle the door state.
	is_open = not is_open
	# Update animation conditions.
	audio.stream = door_sound
	audio.play()
	animation_tree.set("parameters/StateMachine/conditions/is_open", is_open)
	animation_tree.set("parameters/StateMachine/conditions/is_closed", not is_open)

func lock() -> void:
	locked = true
	audio.stream = lock_sound
	audio.play()
	if animation_tree:
		animation_tree.set("parameters/Locked/request", 1)

func unlock() -> void:
	locked = false
	audio.stream = door_sound
	audio.play()
	if animation_tree:
		animation_tree.set("parameters/Locked/active", 0)
