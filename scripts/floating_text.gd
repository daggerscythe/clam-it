extends Node2D

@onready var label: Label = $Label

@export var duration: float = 1.0 # seconds on screen

func setup(text: String, color: Color = Color(0.2, 0.9, 0.3)) -> void:
	label.text = text
	label.add_theme_color_override("font_color", color)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 50, duration)
	tween.tween_property(label, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(queue_free)
