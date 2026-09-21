extends CanvasLayer

@onready var paused_label: Label = $PausedLabel
@onready var pause_button: Button = $PauseButton
@onready var level_up_popup: Node2D = $LevelUpPopup
@onready var pause_menu: Control = $PauseMenu

func _ready() -> void:
	paused_label.visible = false
	pause_menu.visible = false
	pause_button.pressed.connect(toggle_pause)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	if level_up_popup.visible:
		return
	get_tree().paused = not get_tree().paused
	paused_label.visible = get_tree().paused
	pause_menu.visible = get_tree().paused
