extends Control

@onready var texture_rect: TextureRect = $TextureRect

@export var WinImage: CompressedTexture2D = null
@export var LooseImage: CompressedTexture2D = null
@export var WhyEnding: CompressedTexture2D = null
@export var DeathEnding: CompressedTexture2D = null

func _ready() -> void:
	texture_rect.visible = false

func show_ending(image: Texture2D) -> void:
	texture_rect.texture = image
	texture_rect.visible = true
	modulate.a = 1.0
	await get_tree().create_timer(10.0).timeout
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	await tween.finished
	get_tree().change_scene_to_file("res://menuTemplate/scenes/credits/scrolling_credits.tscn")

func show_win() -> void:
	show_ending(WinImage)

func show_loose() -> void:
	show_ending(LooseImage)

func show_why() -> void:
	show_ending(WhyEnding)

func show_death() -> void:
	show_ending(DeathEnding)
