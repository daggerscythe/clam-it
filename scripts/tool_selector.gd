extends Node2D

@onready var hand_slot: TextureRect = $HandSlot
@onready var brush_slot: TextureRect = $BrushSlot
@onready var chum_slot: TextureRect = $ChumSlot
@onready var sonar_slot: TextureRect = $SonarSlot
@onready var selection_highlight: ColorRect = $SelectionHighlight

const HIGHLIGHT_OFFSET: Vector2 = Vector2(-4, -4)

func _ready() -> void:
	PlayerProgress.level_changed.connect(update_unlocked_slots)
	update_unlocked_slots(PlayerProgress.current_level)

func update_unlocked_slots(_new_level: int) -> void:
	hand_slot.visible = PlayerProgress.is_tool_unlocked(Global.Tool.HAND)
	brush_slot.visible = PlayerProgress.is_tool_unlocked(Global.Tool.BRUSH)
	chum_slot.visible = PlayerProgress.is_tool_unlocked(Global.Tool.CHUM)
	sonar_slot.visible = PlayerProgress.is_tool_unlocked(Global.Tool.SONAR)

func _process(_delta: float) -> void:
	match Global.active_tool:
		Global.Tool.HAND:
			selection_highlight.position = hand_slot.position + HIGHLIGHT_OFFSET
		Global.Tool.BRUSH:
			selection_highlight.position = brush_slot.position + HIGHLIGHT_OFFSET
		Global.Tool.CHUM:
			selection_highlight.position = chum_slot.position + HIGHLIGHT_OFFSET
		Global.Tool.SONAR:
			selection_highlight.position = sonar_slot.position + HIGHLIGHT_OFFSET
