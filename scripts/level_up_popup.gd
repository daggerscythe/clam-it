extends Node2D

@onready var title_label: Label = $TitleLabel
@onready var tool_image: TextureRect = $ToolImage
@onready var how_to_use_label: Label = $HowToUseLabel
@onready var what_it_does_label: Label = $WhatItDoesLabel
@onready var got_it_button: Button = $GotItButton

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
	5: {
		"how_to_use": "All tools are unlocked!",
		"what_it_does": "Keep planting, cleaning, and selling to keep progressing. It's you vs the crabs...",
		"image": preload("res://assets/sprites/akoya_pearl.png"),
	},
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	got_it_button.pressed.connect(_on_got_it_pressed)
	PlayerProgress.level_changed.connect(_on_level_changed)

func _on_level_changed(new_level: int) -> void:
	if not LEVEL_UNLOCK_INFO.has(new_level):
		return
	var info: Dictionary = LEVEL_UNLOCK_INFO[new_level]
	title_label.text = "Level %d! You unlocked: " % new_level
	tool_image.texture = info["image"]
	how_to_use_label.text = info["how_to_use"]
	what_it_does_label.text = info["what_it_does"]
	visible = true
	get_tree().paused = true

func _on_got_it_pressed() -> void:
	visible = false
	get_tree().paused = false
