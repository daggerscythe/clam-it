class_name UpgradeCard
extends PanelContainer

signal selected(card: UpgradeCard)

const CARD_WIDTH: float = 260.0
const COLOR_BG: Color = Color(0.08, 0.16, 0.28, 0.95)
const COLOR_BORDER: Color = Color(0.35, 0.55, 0.75)
const COLOR_BORDER_SELECTED: Color = Color(1.0, 0.85, 0.2)

var upgrade_type: int = -1
var style_normal: StyleBoxFlat
var style_selected: StyleBoxFlat
var content: VBoxContainer
var subtitle_label: Label

# generates a card for an upgrade type
func setup(type: int) -> void:
	upgrade_type = type
	build(PlayerProgress.UPGRADE_DATA[type]["icon"], PlayerProgress.get_upgrade_name(type), PlayerProgress.get_upgrade_effect_text(type, 1))

# card for any shop item
func build(icon_texture: Texture2D, title: String, description: String) -> void:
	custom_minimum_size = Vector2(CARD_WIDTH, 300)
	mouse_filter = Control.MOUSE_FILTER_STOP
	style_normal = make_style(COLOR_BORDER, 3)
	style_selected = make_style(COLOR_BORDER_SELECTED, 7)
	add_theme_stylebox_override("panel", style_normal)
	
	content = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 10)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	
	var icon: TextureRect = TextureRect.new()
	icon.texture = icon_texture
	icon.custom_minimum_size = Vector2(96, 96)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	
	add_label(title, 26)
	add_label(description, 20)
	subtitle_label = add_label("", 20)

# sets the subtitle of the card 
func set_subtitle(text: String) -> void:
	subtitle_label.text = text

# adds a "buy" button to card
func add_button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	content.add_child(button)
	return button

# makes the card appear selected
func set_selected(is_selected: bool) -> void:
	add_theme_stylebox_override("panel", style_selected if is_selected else style_normal)

# adds a label to the card, duh
func add_label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.x = CARD_WIDTH - 30
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(label)
	return label

# governs the style of the card
func make_style(border_color: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = COLOR_BG
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(15)
	return style

# emits selected when the card is clicked
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Sfx.play_select()
		selected.emit(self)
