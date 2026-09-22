extends Control

signal closed

@onready var title_label: Label = $TitleLabel
@onready var card_row: HBoxContainer = $CardRow
@onready var info_label: Label = $InfoLabel
@onready var save_button: Button = $SaveButton
@onready var buy_button: Button = $BuyButton

var selected_card: UpgradeCard = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	save_button.pressed.connect(_on_save_pressed)
	buy_button.pressed.connect(_on_buy_pressed)

# reutrns false if all upgrades bought
func open(level: int) -> bool:
	var choices: Array = PlayerProgress.roll_upgrade_choices(3)
	if choices.is_empty():
		return false
	
	for child in card_row.get_children():
		card_row.remove_child(child)
		child.queue_free()
	selected_card = null
	
	for type in choices:
		var card: UpgradeCard = UpgradeCard.new()
		card_row.add_child(card)
		card.setup(type)
		card.set_subtitle("Cost: $%d" % PlayerProgress.get_upgrade_cost(type))
		card.selected.connect(_on_card_selected)
	
	title_label.text = "Level %d! Choose an upgrade:" % level
	refresh_buttons()
	visible = true
	return true

func refresh_buttons() -> void: 
	var has_selection: bool = selected_card != null
	save_button.disabled = not has_selection
	buy_button.disabled = not has_selection or not PlayerProgress.can_buy_upgrade(selected_card.upgrade_type)
	if not has_selection:
		info_label.text = "Select a card."
	elif buy_button.disabled:
		info_label.text = "Not enough money, broke boy!"
	else:
		info_label.text = ""

func close() -> void:
	visible = false
	closed.emit()

func _on_card_selected(card: UpgradeCard) -> void:
	if selected_card:
		selected_card.set_selected(false)
	selected_card = card
	selected_card.set_selected(true)
	refresh_buttons()

func _on_save_pressed() -> void:
	PlayerProgress.save_upgrade_for_later(selected_card.upgrade_type)
	close()

func _on_buy_pressed() -> void:
	if PlayerProgress.buy_upgrade(selected_card.upgrade_type, false):
		close()
