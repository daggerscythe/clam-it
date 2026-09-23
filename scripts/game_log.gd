extends Node

signal message_added(line: String)

const MAX_MESSAGES: int = 60
const COLOR_INFO: Color = Color(0.92, 0.92, 0.92)
const COLOR_GOOD: Color = Color(0.35, 0.9, 0.4)
const COLOR_WARN: Color = Color(1.0, 0.55, 0.3)
const COLOR_EVENT: Color = Color(1.0, 0.85, 0.3)

var history: Array[String] = []

func info(text: String) -> void:
	_add(text, COLOR_INFO)

func good(text: String) -> void:
	_add(text, COLOR_GOOD)

func warn(text: String) -> void:
	_add(text, COLOR_WARN)

func event(text: String) -> void:
	_add(text, COLOR_EVENT)

func _add(text: String, color: Color) -> void:
	print(text) # for debugging
	var line: String = "[color=#%s]%s[/color]" % [color.to_html(false), text]
	history.append(line)
	if history.size() > MAX_MESSAGES:
		history.pop_front()
	message_added.emit(line)
