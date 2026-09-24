extends CanvasLayer

@onready var paused_label: Label = $PausedLabel
@onready var pause_button: Button = $PauseButton
@onready var intro_popup: Control = $IntroPopup
@onready var level_up_popup: Node2D = $LevelUpPopup
@onready var upgrades_menu: Control = $UpgradesMenu
@onready var pause_menu: Control = $PauseMenu
@onready var save_button: Button = $PauseMenu/Buttons/SaveButton
@onready var load_button: Button = $PauseMenu/Buttons/LoadButton
@onready var settings_button: Button = $PauseMenu/Buttons/SettingsButton
@onready var exit_button: Button = $PauseMenu/Buttons/ExitButton
@onready var status_label: Label = $PauseMenu/StatusLabel
@onready var settings_panel: Control = $SettingsPanel
@onready var infinite_flares_toggle: CheckButton = $SettingsPanel/Toggles/InfiniteFlaresToggle
@onready var instant_clean_toggle: CheckButton = $SettingsPanel/Toggles/InstantCleanToggle
@onready var instant_chum_toggle: CheckButton = $SettingsPanel/Toggles/InstantChumToggle
@onready var settings_back_button: Button = $SettingsPanel/BackButton

func _ready() -> void:
	paused_label.visible = false
	pause_menu.visible = false
	settings_panel.visible = false
	status_label.text = ""
	
	pause_button.pressed.connect(toggle_pause)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(open_settings)
	exit_button.pressed.connect(_on_exit_pressed)
	settings_back_button.pressed.connect(close_settings)
	
	# re-sync setting toggles after a scene reload
	infinite_flares_toggle.button_pressed = Global.infinite_flares
	instant_clean_toggle.button_pressed = Global.instant_clean
	instant_chum_toggle.button_pressed = Global.instant_chum
	infinite_flares_toggle.toggled.connect(func(on: bool) -> void: Global.infinite_flares = on)
	instant_clean_toggle.toggled.connect(func(on: bool) -> void: Global.instant_clean = on)
	instant_chum_toggle.toggled.connect(func(on: bool) -> void: Global.instant_chum = on)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_panel.visible:
			close_settings()
		else:
			toggle_pause()

func toggle_pause() -> void:
	if level_up_popup.is_showing or intro_popup.visible:
		return
	if upgrades_menu.visible:
		upgrades_menu.close()
		return
	var now_paused: bool = not get_tree().paused
	get_tree().paused = now_paused
	paused_label.visible = now_paused
	pause_menu.visible = now_paused
	settings_panel.visible = false
	status_label.text = ""

func open_settings() -> void:
	pause_menu.visible = false
	settings_panel.visible = true

func close_settings() -> void:
	settings_panel.visible = false
	pause_menu.visible = true

func _on_save_pressed() -> void:
	status_label.text = "Game saved!" if PlayerProgress.save_game() else "Save failed :("

func _on_load_pressed() -> void:
	if not PlayerProgress.load_game(): # on success the scene reloads, so nothing else to do
		status_label.text = "No save file found."

func _on_exit_pressed() -> void:
	get_tree().quit()
