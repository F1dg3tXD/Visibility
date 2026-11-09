extends Node3D

var _compressing: bool = false
var _compress_start: float = 0.0
var _compress_duration: float = 0.0

func _ready() -> void:
	var shit_meter = get_node_or_null("shitMeter")
	if shit_meter:
		shit_meter.warning_reached.connect(_on_shit_meter_warning_reached)
		shit_meter.time_ended.connect(_on_shit_meter_time_ended)

func _process(delta: float) -> void:
	if _compressing:
		_compress_start += delta
		var t := clampf(_compress_start / _compress_duration, 0.0, 1.0)
		var bus := AudioServer.get_bus_index("Music")
		if bus >= 0:
			var fx := AudioServer.get_bus_effect(bus, 0)
			if fx is AudioEffectCompressor:
				fx.ratio = lerpf(1.0, 50.0, t)

func _on_shit_meter_warning_reached(percent: float) -> void:
	_compressing = true
	_compress_start = 0.0
	# remaining time until end
	var shit_meter = get_node_or_null("shitMeter")
	if shit_meter:
		_compress_duration = shit_meter.TimeLimit * (1.0 - percent)

func _on_shit_meter_time_ended() -> void:
	_compressing = false
	var bus := AudioServer.get_bus_index("Music")
	if bus >= 0:
		var fx := AudioServer.get_bus_effect(bus, 0)
		if fx is AudioEffectCompressor:
			fx.ratio = 48.0
