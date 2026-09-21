extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Global.active_tool == Global.Tool.HAND:
			PlayerProgress.sell_all_pearls()
