#shit_meter.gd
extends Control

# The progress bar
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar

# The time limit to beat before the game-end signal (in seconds).
@export var TimeLimit: float = 30.0
@export var MaxTime: float = 120.0
# Fraction (0-1) of the bar at which the warning is emitted.
@export var WarningTime: float = 0.95

signal time_ended
signal warning_reached(percent: float)

var _elapsed: float = 0.0
var _running: bool = false
var _warning_emitted: bool = false

func _ready() -> void:
	MaxTime = maxf(MaxTime, 0.001)
	texture_progress_bar.max_value = 100.0
	texture_progress_bar.value = 0.0
	set_time(TimeLimit)
	start()

# Set the timer duration in seconds.
func set_time(seconds: float) -> void:
	TimeLimit = clampf(seconds, 0.001, MaxTime)
	_elapsed = 0.0
	_warning_emitted = false
	if texture_progress_bar:
		texture_progress_bar.value = 0.0


func start() -> void:
	TimeLimit = clampf(TimeLimit, 0.001, MaxTime)
	_elapsed = 0.0
	_warning_emitted = false
	_running = true
	if texture_progress_bar:
		texture_progress_bar.value = 0.0


func stop() -> void:
	_running = false


func stop_and_hide() -> void:
	stop()
	visible = false


# Add time without exceeding MaxTime.
func add_time(seconds: float) -> void:
	if seconds <= 0.0:
		return
	# Calculate the actual remaining time.
	var remaining_time: float = maxf(TimeLimit - _elapsed, 0.0)
	# Add time, but enforce the maximum.
	remaining_time = minf(remaining_time + seconds, MaxTime)
	# Update the total duration while preserving elapsed time.
	TimeLimit = _elapsed + remaining_time


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
