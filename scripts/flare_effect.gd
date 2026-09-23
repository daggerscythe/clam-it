class_name FlareEffect
extends Sprite2D

const SHEET: Texture2D = preload("res://assets/sprites/sonic_flare_animation.png")
const FRAME_COUNT: int = 5
const FRAME_SIZE: float = 164.0
const EXPAND_TIME: float = 0.4
const FADE_TIME: float = 0.25

func play(radius: float) -> void:
	texture = SHEET
	vframes = FRAME_COUNT
	frame = 0
	z_index = 10
	var s: float = (radius * 2.0) / FRAME_SIZE
	scale = Vector2(s, s)
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "frame", FRAME_COUNT - 1, EXPAND_TIME)
	tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(queue_free)
