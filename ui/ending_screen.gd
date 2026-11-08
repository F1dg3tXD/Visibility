extends Control

@onready var texture_rect: TextureRect = $TextureRect

@export var WinImage: CompressedTexture2D = null
@export var LooseImage: CompressedTexture2D = null
@export var WhyEnding: CompressedTexture2D = null
@export var DeathEnding: CompressedTexture2D = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
