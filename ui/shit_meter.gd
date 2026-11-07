extends Control

# The progress bar
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar

# The time limit to beat before the game-end signal (in seconds).
@export var TimeLimit: float = 30.0
# Fraction (0-1) of the bar at which the warning is emitted.
@export var WarningTime: float = 0.95

signal time_ended
signal warning_reached(percent: float)

var _elapsed: float = 0.0
var _running: bool = false
var _warning_emitted: bool = false

func _ready() -> void:
	texture_progress_bar.max_value = 100.0
	texture_progress_bar.value = 0.0
	set_time(TimeLimit)
	start()

# Set the timer duration in seconds.
func set_time(seconds: float) -> void:
	TimeLimit = max(seconds, 0.001)
	_elapsed = 0.0
	_warning_emitted = false
	if texture_progress_bar:
		texture_progress_bar.value = 0.0

func start() -> void:
	_elapsed = 0.0
	_warning_emitted = false
	_running = true
	if texture_progress_bar:
		texture_progress_bar.value = 0.0

func stop() -> void:
	_running = false

func _process(delta: float) -> void:
	if not _running:
		return
	_elapsed += delta
	var ratio := clampf(_elapsed / TimeLimit, 0.0, 1.0)
	texture_progress_bar.value = ratio * 100.0
	if not _warning_emitted and ratio >= WarningTime:
		_warning_emitted = true
		warning_reached.emit(ratio)
	if ratio >= 1.0:
		_running = false
		time_ended.emit()
