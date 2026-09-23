extends Node

const SLOT_OUTLINE: StyleBox = preload("res://theme/slot_outline.tres")
const ICON_SIZE: float = 64.0
const SLOT_SPACING: float = 74.0 # 64px icon + outline + gap

var count_labels: Dictionary = {} # PearlType -> Label

func _ready() -> void:
	PlayerProgress.level_changed.connect(_on_level_changed)
	rebuild_slots()

func _on_level_changed(_new_level: int) -> void:
	rebuild_slots()

func _process(_delta: float) -> void:
	for type in count_labels:
		count_labels[type].text = str(PlayerProgress.held_pearls.get(type, 0))

# creates one slot per unlocked pearl type
func rebuild_slots() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	count_labels.clear()
	
	var types: Array = PlayerProgress.get_unlocked_pearl_types()
	for i in types.size():
		var slot: Node2D = make_slot(types[i])
		slot.position = Vector2(-SLOT_SPACING * i, 0)

func make_slot(type: int) -> Node2D:
	var slot: Node2D = Node2D.new()
	add_child(slot)
	
	var outline: Panel = Panel.new()
	outline.add_theme_stylebox_override("panel", SLOT_OUTLINE)
	outline.position = Vector2(-3, -3)
	outline.size = Vector2(ICON_SIZE + 6, ICON_SIZE + 6)
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(outline)
	
	var icon: TextureRect = TextureRect.new()
	icon.texture = PlayerProgress.get_pearl_texture(type)
	icon.size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	
	var label: Label = Label.new()
	label.position = Vector2(43, 27)
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color.BLACK)
	# white outline so the number stays readable on dark pearls (Tahitian)
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(label)
	
	count_labels[type] = label
	return slot
