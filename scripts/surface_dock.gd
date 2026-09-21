extends Area2D

const FLOATING_TEXT_SCENE: PackedScene = preload("res://scenes/floating_text.tscn")
const COLOR_MONEY: Color = Color(0.2, 0.9, 0.3)
const COLOR_WARNING: Color = Color(0.9, 0.15, 0.15)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Global.active_tool == Global.Tool.HAND:
			var earned: int = PlayerProgress.sell_all_pearls()
			var click_position: Vector2 = get_global_mouse_position()
			if earned > 0:
				spawn_floating_text("+ $%d" % earned, click_position, COLOR_MONEY)
			else:
				spawn_floating_text("No pearls to sell!", click_position, COLOR_WARNING)

func spawn_floating_text(text: String, spawn_position: Vector2, color: Color) -> void:
	var floating_text = FLOATING_TEXT_SCENE.instantiate()
	get_tree().current_scene.add_child(floating_text)
	floating_text.global_position = spawn_position
	floating_text.setup(text, color)
