extends Node2D

@onready var title_label: Label = $TitleLabel
@onready var tool_image: TextureRect = $ToolImage
@onready var how_to_use_label: Label = $HowToUseLabel
@onready var what_it_does_label: Label = $WhatItDoesLabel
@onready var got_it_button: Button = $GotItButton
@onready var upgrade_pick_popup: Control = $"../UpgradePickPopup"

const LEVEL_UNLOCK_INFO: Dictionary = {
	2: {
		"how_to_use": "Press 2 or B to select the Brush, then click a dirty clam to scrub it.",
		"what_it_does": "Growing clams now accumulate sediment! Keep them clean by scrubbing.",
		"image": preload("res://assets/sprites/brush.png"),
	},
	3: {
		"how_to_use": "Press 3 or C to select Chum, then click a growing clam.",
		"what_it_does": "Chum instantly speeds up a pearl's growth, but using it wil make your environment very chummy",
		"image": preload("res://assets/sprites/chum.png"),
	},
	4: {
		"how_to_use": "Press 4 or F to select the Flare, then click near an approaching crab.",
		"what_it_does": "Crabs are attracted to chum and will destroy a growing pearl if they reach it! Use the Sonic Flare to scare them off.",
		"image": preload("res://assets/sprites/sonic_flare_icon.png"),
	},
}

# entries: {"kind": "info"/"upgrade", "level": int, "info": Dictionary}
var popup_queue: Array = []
var is_showing: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	got_it_button.pressed.connect(_on_got_it_pressed)
	upgrade_pick_popup.closed.connect(show_next_popup)
	PlayerProgress.level_changed.connect(_on_level_changed)

func _on_level_changed(new_level: int) -> void:
	if LEVEL_UNLOCK_INFO.has(new_level):
		popup_queue.append({"kind": "info", "level": new_level, "info": LEVEL_UNLOCK_INFO[new_level]})
	
	var new_pearl: int = PlayerProgress.get_pearl_unlocked_at_level(new_level)
	if new_pearl != -1:
		popup_queue.append({"kind": "info", "level": new_level, "info": make_pearl_info(new_pearl)})
	
	if new_level >= PlayerProgress.FREEPLAY_START_LEVEL:
		popup_queue.append({"kind": "upgrade", "level": new_level})
	
	if not is_showing:
		show_next_popup()

func make_pearl_info(type: int) -> Dictionary:
	var data: Dictionary = PlayerProgress.PEARL_DATA[type]
	return {
		"how_to_use": "New pearl: %s. Sells for $%d!" % [data["name"], data["price"]],
		"what_it_does": "It can now appear when a pearl matures. Rarer pearls are worth more money and XP.",
		"image": data["texture"],
	}

func show_next_popup() -> void:
	if popup_queue.is_empty():
		is_showing = false
		visible = false
		get_tree().paused = false
		return
	
	is_showing = true
	get_tree().paused = true
	var entry: Dictionary = popup_queue.pop_front()
	if entry["kind"] == "info":
		show_info(entry["level"], entry["info"])
	else:
		visible = false
		if not upgrade_pick_popup.open(entry["level"]):
			show_next_popup()

func show_info(level: int, info: Dictionary) -> void:
	title_label.text = "Level %d! You unlocked: " % level
	tool_image.texture = info["image"]
	how_to_use_label.text = info["how_to_use"]
	what_it_does_label.text = info["what_it_does"]
	visible = true

func _on_got_it_pressed() -> void:
	visible = false
	show_next_popup()
