extends Node2D

const CHUM_BAR_WIDTH: float = 270.0
const XP_BAR_WIDTH: float = 300.0

@onready var chum_bar_fill: ColorRect = $ChumMeterBar/MeterFill
@onready var chum_bar_tick: ColorRect = $ChumMeterBar/ThresholdTick
@onready var level_label: Label = $XPBarRoot/LevelLabel
@onready var xp_bar_fill: ColorRect = $XPBarRoot/BarFill
@onready var xp_label: Label = $XPBarRoot/XPLabel
@onready var money_label: Label = $Money/MoneyLabel

func _ready() -> void:
	PlayerProgress.money_changed.connect(update_money_label)
	update_money_label(PlayerProgress.money)

func _process(_delta: float) -> void:
	var fraction: float = clamp(Global.chum_meter / Global.CHUM_METER_MAX, 0.0, 1.0)
	chum_bar_fill.size.x = CHUM_BAR_WIDTH * fraction
	# threshold can change with upgrades so i moved it from ready to process
	var threshold_fraction: float = PlayerProgress.get_crab_spawn_threshold() / Global.CHUM_METER_MAX
	chum_bar_tick.position.x = CHUM_BAR_WIDTH * threshold_fraction
	update_xp_bar()

func _unhandled_input(event: InputEvent) -> void:
	if Global.active_tool == Global.Tool.SONAR and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			fire_sonic_flare(get_global_mouse_position())

func update_xp_bar() -> void:
	var level: int = PlayerProgress.current_level
	level_label.text = "LVL %d" % level
	if PlayerProgress.is_max_level():
		xp_bar_fill.size.x = XP_BAR_WIDTH
		xp_label.text = "MAX LEVEL"
		return
	var level_start: int = PlayerProgress.get_xp_at_level_start(level)
	var level_end: int = PlayerProgress.get_xp_to_finish_level(level)
	var xp_into_level: int = PlayerProgress.current_xp - level_start
	var xp_needed: int = level_end - level_start
	var fraction: float = clamp(float(xp_into_level) / float(xp_needed), 0.0, 1.0)
	xp_bar_fill.size.x = XP_BAR_WIDTH * fraction
	xp_label.text = "%d / %d" % [xp_into_level, xp_needed]

func update_money_label(new_money: int) -> void:
	money_label.text = str(new_money)

func fire_sonic_flare(click_position: Vector2) -> void:
	if not PlayerProgress.use_flare():
		GameLog.warn("Out of sonic flares! Buy more in the Shop.")
		return
	
	var radius: float = PlayerProgress.get_flare_radius()
	spawn_flare_effect(click_position, radius)
	
	var scared_count: int = 0
	for crab in get_tree().get_nodes_in_group("crabs"):
		if crab.global_position.distance_to(click_position) <= radius:
			crab.scare_off()
			scared_count += 1
	
	if scared_count > 0:
		GameLog.good("Sonic flare scared off %d crab(s)!" % scared_count)
	else:
		GameLog.info("Sonic flare missed. No crabs in range.")

func spawn_flare_effect(at_position: Vector2, radius: float) -> void:
	var effect: FlareEffect = FlareEffect.new()
	add_child(effect)
	effect.global_position = at_position
	effect.play(radius)
