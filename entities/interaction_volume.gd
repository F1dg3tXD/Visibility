
extends Area3D

signal interacted
signal hovered
signal interact_pressed

@onready var promt_graphics: Sprite3D = $promtGraphics
@onready var interact_label: Label = $SubViewport/Control/VBoxContainer/interactLabel
@onready var input_icon: TextureRect = $SubViewport/Control/VBoxContainer/inputIcon

@export var prompt: String = "Interact"

var _mapper: InputIconMapper = null
var _last_input_event: InputEvent = null
var _is_hovered: bool = false


func _ready() -> void:
	add_to_group("interactable")

	promt_graphics.visible = false
	interact_label.text = prompt

	_mapper = _find_input_icon_mapper(get_tree().root)

	if _mapper:
		if not _mapper.joypad_device_changed.is_connected(_update_input_icon):
			_mapper.joypad_device_changed.connect(_update_input_icon)


# Find the InputIconMapper anywhere in the scene tree.
func _find_input_icon_mapper(node: Node) -> InputIconMapper:
	if node is InputIconMapper:
		return node

	for child in node.get_children():
		var found := _find_input_icon_mapper(child)
		if found:
			return found

	return null


# Update the keyboard/controller input icon.
func _update_input_icon() -> void:
	if _mapper == null:
		return

	var want_joypad := (
		_last_input_event is InputEventJoypadButton
		or _last_input_event is InputEventJoypadMotion
	)

	var events := InputMap.action_get_events("interact")

	for event in events:
		var is_joy := (
			event is InputEventJoypadButton
			or event is InputEventJoypadMotion
		)

		if is_joy == want_joypad:
			var tex := _mapper.get_icon(event)

			if tex:
				input_icon.texture = tex
				return

	if events.size() > 0:
		var fallback := _mapper.get_icon(events[0])
		if fallback:
			input_icon.texture = fallback


# Called by the player when the raycast targets this volume.
func set_hovered(value: bool) -> void:
	if _is_hovered == value:
		return

	_is_hovered = value
	promt_graphics.visible = value

	if value:
		_update_input_icon()
		hovered.emit()


# Allows the player to update the input icon before handling an input event.
func register_input_event(event: InputEvent) -> void:
	_last_input_event = event

	if _is_hovered:
		_update_input_icon()


func _input(event: InputEvent) -> void:
	register_input_event(event)


# Called by the player when the interact action is pressed.
func interact() -> void:
	interact_pressed.emit()
	interacted.emit()
