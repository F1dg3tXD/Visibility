extends Node3D

@onready var animation_tree: AnimationTree = $AnimationTree

@export var locked: bool = false

var _is_open: bool = false

func _ready() -> void:
	if animation_tree:
		animation_tree.active = true
	# Hook up any interaction volume in the subtree.
	for node in find_children("*", "Area3D", true, false):
		if node.has_signal("interacted"):
			if not node.interacted.is_connected(interact):
				node.interacted.connect(interact)

func interact() -> void:
	if animation_tree == null:
		push_warning("No AnimationTree found")
		return
	if locked:
		animation_tree.set("parameters/conditions/locked", true)
		animation_tree.set("parameters/conditions/!locked", false)
	else:
		if not _is_open:
			_is_open = true
			animation_tree.set("parameters/conditions/!locked", true)
			animation_tree.set("parameters/conditions/locked", false)
			animation_tree.set("parameters/conditions/!_is_open", false)
		else:
			_is_open = false
			animation_tree.set("parameters/conditions/!_is_open", true)

func lock() -> void:
	locked = true

func unlock() -> void:
	locked = false
