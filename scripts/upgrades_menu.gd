extends Control

const FLARE_ICON: Texture2D = preload("res://assets/sprites/sonic_flare_icon.png")
const TAB_AVAILABLE: int = 0
const TAB_OWNED: int = 1
const TAB_SUPPLIES: int = 2

@onready var tabs: TabContainer = $Tabs
@onready var available_cards: HBoxContainer = $Tabs/Available/Cards
@onready var owned_cards: HBoxContainer = $Tabs/Owned/Cards
@onready var supply_cards: HBoxContainer = $Tabs/Supplies/Cards
@onready var status_label: Label = $StatusLabel
@onready var close_button: Button = $CloseButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	close_button.pressed.connect(close)
	PlayerProgress.upgrades_changed.connect(_on_progress_changed)
	PlayerProgress.money_changed.connect(_on_progress_changed)

func open() -> void:
	# shop is supplies only until free-play
	var in_freeplay: bool = PlayerProgress.current_level >= PlayerProgress.FREEPLAY_START_LEVEL
	if not in_freeplay:
		tabs.current_tab = TAB_SUPPLIES
	tabs.set_tab_hidden(TAB_AVAILABLE, not in_freeplay)
	tabs.set_tab_hidden(TAB_OWNED, not in_freeplay)
	refresh()
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false 
	get_tree().paused = false

func refresh() -> void:
	clear_cards(available_cards)
	clear_cards(owned_cards)
	clear_cards(supply_cards)
	var has_available: bool = false
	
	for type in PlayerProgress.UPGRADE_DATA:
		# AVAILABLE
		var pending: int = PlayerProgress.get_pending(type)
		if pending > 0: 
			has_available = true
			var card: UpgradeCard = UpgradeCard.new()
			available_cards.add_child(card)
			card.setup(type)
			card.set_subtitle("x%d waiting \nCost: $%d" % [pending, PlayerProgress.get_upgrade_cost(type)])
			var buy_button: Button = card.add_button("Buy")
			buy_button.disabled = not PlayerProgress.can_buy_upgrade(type)
			buy_button.pressed.connect(_on_buy_pressed.bind(type))
		
		# OWNED
		var owned: int = PlayerProgress.get_owned(type)
		if owned > 0:
			var card: UpgradeCard = UpgradeCard.new()
			owned_cards.add_child(card)
			card.setup(type)
			card.set_subtitle("%d purchased\n%s total" % [owned, PlayerProgress.get_upgrade_effect_text(type, owned)])
	
	# SUPPLIES
	add_flare_card()
	
	status_label.text = "Money: $%d" % PlayerProgress.money
	if not has_available:
		status_label.text += "   (No saved upgrades)"

func add_flare_card() -> void:
	var card: UpgradeCard = UpgradeCard.new()
	supply_cards.add_child(card)
	card.build(FLARE_ICON, "Sonic Flare", "Scares off nearby crabs.")
	var ammo_text: String = "∞" if Global.infinite_flares else str(PlayerProgress.sonar_ammo)
	card.set_subtitle("You have: %s\nCost: $%d" % [ammo_text, PlayerProgress.FLARE_PRICE])
	var buy_button: Button = card.add_button("Buy")
	buy_button.disabled = PlayerProgress.money < PlayerProgress.FLARE_PRICE
	buy_button.pressed.connect(_on_buy_flare_pressed)

func clear_cards(container: HBoxContainer) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _on_buy_pressed(type: int) -> void:
	PlayerProgress.buy_upgrade(type, true)

func _on_buy_flare_pressed() -> void:
	if not PlayerProgress.buy_flare():
		GameLog.warn("Not enough money for a flare!") 

# deferred so a buy button isn't freed while it's emitting pressed
func _on_progress_changed(_value = null) -> void:
	refresh.call_deferred()
