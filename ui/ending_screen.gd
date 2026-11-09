extends Control

@onready var texture_rect: TextureRect = $TextureRect
@onready var ending_audio: AudioStreamPlayer = $EndingAudio

@export var WinImage: CompressedTexture2D = null
@export var WinAudio: AudioStream = null
@export var LooseImage: CompressedTexture2D = null
@export var LooseAudio: AudioStream = null
@export var WhyEnding: CompressedTexture2D = null
@export var WhyAudio: AudioStream = null
@export var DeathEnding: CompressedTexture2D = null
@export var DeathAudio: AudioStream = null

@export_range(-80.0, 6.0, 0.1) var ending_volume_db: float = 0.0


const black := Color(0.0, 0.0, 0.0, 1.0)
const white := Color(1.0, 1.0, 1.0, 1.0)

func _ready() -> void:
	texture_rect.visible = false

func show_ending(image: Texture2D, audio: AudioStream) -> void:
	texture_rect.texture = image
	ending_audio.stream = audio
	ending_audio.volume_db = ending_volume_db
	ending_audio.play()
	texture_rect.visible = true
	var intween := create_tween()
	modulate.a = 1.0
	modulate.r = 0.0
	modulate.g = 0.0
	modulate.b = 0.0
	#await 5
	intween.tween_property(self, "modulate", Color.WHITE, 1.0)
	await get_tree().create_timer(10.0).timeout
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.BLACK, 1.0)
	tween.tween_property(ending_audio, "volume_db", -80.0, 1.0)
	await tween.finished
	SceneLoader.load_scene("res://menuTemplate/scenes/credits/scrolling_credits.tscn")

func set_ending_volume(volume_db: float) -> void:
	ending_volume_db = clampf(volume_db, -80.0, 6.0)
	ending_audio.volume_db = ending_volume_db

func show_win() -> void:
	show_ending(WinImage, WinAudio)

func show_loose() -> void:
	show_ending(LooseImage, LooseAudio)

func show_why() -> void:
	show_ending(WhyEnding, WhyAudio)

func show_death() -> void:
	show_ending(DeathEnding, DeathAudio)
