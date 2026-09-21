extends Node

signal level_changed(new_level: int)

# XP AWARDS
const PLANT_XP: int = 2
const CHUM_XP: int = 2
const HARVEST_XP: int = 3
const FLARE_XP: int = 5
const SELL_XP_PER_PEARL: int = 40

# PEARLS TO BE SOLD TO ADVANCE
const LEVEL_PEARLS_REQUIRED: Array[int] = [1, 2, 3, 3]

# GROWTH TIME PER LEVEL
const LEVEL_GROWTH_TIMES: Array[float] = [5.0, 10.0, 30.0, 30.0]

var current_level: int = 1
var current_xp: int = 0
var held_pearls: int = 0

# computer at startup
var level_xp_thresholds: Array[int] = []

func _ready() -> void:
	var cumulative: int = 0
	var xp_per_pearl_cycle: int = PLANT_XP + HARVEST_XP + SELL_XP_PER_PEARL
	for pearls_needed in LEVEL_PEARLS_REQUIRED:
		cumulative += pearls_needed * xp_per_pearl_cycle
		level_xp_thresholds.append(cumulative)

func award_xp(amount: int) -> void:
	current_xp += amount
	check_level_up()

func check_level_up() -> void:
	while current_level - 1 < level_xp_thresholds.size() and current_xp >= level_xp_thresholds[current_level - 1]:
		current_level += 1
		print("LEVEL UP! Now level ", current_level)
		apply_level_unlocks()

func apply_level_unlocks() -> void:
	var new_growth_time: float = get_growth_time_for_level(current_level)
	for clam in get_tree().get_nodes_in_group("clams"):
		clam.growth_time = new_growth_time
		clam.set_unlocked(current_level >= clam.unlock_level)
	level_changed.emit(current_level)

func get_growth_time_for_level(level: int) -> float:
	var index: int = clamp(level - 1, 0, LEVEL_GROWTH_TIMES.size() - 1)
	return LEVEL_GROWTH_TIMES[index]

func collect_pearl() -> void:
	held_pearls += 1
	award_xp(HARVEST_XP)

func sell_all_pearls() -> void:
	if held_pearls <= 0:
		print("No pearls to sell!")
		return
	var earned: int = held_pearls * SELL_XP_PER_PEARL
	print("Sold ", held_pearls, " pearl(s) for ", earned, " XP!")
	held_pearls = 0
	award_xp(earned)

func is_tool_unlocked(tool: Global.Tool) -> bool:
	match tool:
		Global.Tool.HAND:
			return true
		Global.Tool.BRUSH:
			return current_level >= 2
		Global.Tool.CHUM:
			return current_level >= 3
		Global.Tool.SONAR:
			return current_level >= 4
		_:
			return false
