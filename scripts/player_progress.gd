extends Node

signal level_changed(new_level: int)
signal money_changed(new_money: int)
signal upgrades_changed

# XP AWARDS
const PLANT_XP: int = 2
const CHUM_XP: int = 2
const HARVEST_XP: int = 3
const FLARE_XP: int = 5
const SELL_XP_PER_PEARL: int = 40

# STAGE 1: PEARLS TO BE SOLD TO ADVANCE
const LEVEL_PEARLS_REQUIRED: Array[int] = [1, 2, 3, 3]

# BASE GROWTH TIME PER LEVEL
const LEVEL_GROWTH_TIMES: Array[float] = [5.0, 10.0, 30.0, 30.0]

# FREEPLAY XP CURVE
# level N cost = BASE + STEP * N^1.5
const FREEPLAY_START_LEVEL: int = 5
const FREEPLAY_BASE_XP: float = 300.0
const FREEPLAY_STEP: float = 60.0

# SONIC FLARE VARIABLES
const SONAR_UNLOCK_LEVEL: int = 4
const FLARES_ON_UNLOCK: int = 5
const FLARES_PER_LEVEL: int = 1
const FLARE_PRICE: int = 30
const FLARE_BASE_RADIUS: float = 250.0

# CRAB DIFFICULTY
const BASE_MAX_CRABS: int = 4
const LEVELS_PER_EXTRA_CRAB: int = 3 

# PEARLS
enum PearlType { CLASSIC, BLUSH, TAHITIAN, SOUTH_SEA, CONCH, MELO, ABALONE }
const PEARL_DATA: Dictionary = {
	PearlType.CLASSIC: {
		"name": "Classic Pearl", 
		"price": 200, 
		"xp": 40, 
		"weight": 40, 
		"unlock_level": 1,
		"texture": preload("res://assets/sprites/akoya_pearl.png")
	},
	PearlType.BLUSH: {
		"name": "Blush Pearl", 
		"price": 300, 
		"xp": 50, 
		"weight": 22, 
		"unlock_level": 5,
		"texture": preload("res://assets/sprites/blush_pearl.png")
	},
	PearlType.TAHITIAN: {
		"name": "Tahitian Pearl", 
		"price": 450, 
		"xp": 65, 
		"weight": 15, 
		"unlock_level": 7,
		"texture": preload("res://assets/sprites/tahitian_pearl.png")
	},
	PearlType.SOUTH_SEA: {
		"name": "Golden South Sea Pearl", 
		"price": 650, 
		"xp": 85, 
		"weight": 10, 
		"unlock_level": 9,
		"texture": preload("res://assets/sprites/southsea_pearl.png")
	},
	PearlType.CONCH: {
		"name": "Conch Pearl", 
		"price": 900, 
		"xp": 110, 
		"weight": 7, 
		"unlock_level": 11,
		"texture": preload("res://assets/sprites/conch_pearl.png")
	},
	PearlType.MELO: {
		"name": "Melo Pearl", 
		"price": 1200, 
		"xp": 140, 
		"weight": 4, 
		"unlock_level": 13,
		"texture": preload("res://assets/sprites/melo_pearl.png")
	},
	PearlType.ABALONE: {
		"name": "Abalone Pearl", 
		"price": 1600, 
		"xp": 180, 
		"weight": 2, 
		"unlock_level": 15,
		"texture": preload("res://assets/sprites/abalone_pearl.png")
	},
}

# UPGRADES
enum UpgradeType { CLAM_SLOT, GROWTH_SPEED, FLARE_RADIUS, CHUM_THRESHOLD }
const UPGRADE_DATA: Dictionary = {
	UpgradeType.CLAM_SLOT: {
		"name": "New Clam Slot", 
		"base_cost": 600, 
		"cost_multiplier": 1.8,
		"icon": preload("res://assets/sprites/new_clam_slot.png")
	},
	UpgradeType.GROWTH_SPEED: {
		"name": "Faster Growth", 
		"base_cost": 300, 
		"cost_multiplier": 1.35,
		"icon": preload("res://assets/sprites/growth_boost.png")
	},
	UpgradeType.FLARE_RADIUS: {
		"name": "Bigger Flare", 
		"base_cost": 250, 
		"cost_multiplier": 1.4,
		"icon": preload("res://assets/sprites/increase_sonic_radius.png")
	},
	UpgradeType.CHUM_THRESHOLD: {
		"name": "Crab Tolerance", 
		"base_cost": 250, 
		"cost_multiplier": 1.4,
		"icon": preload("res://assets/sprites/chum_threshold_increase.png")
	},
}

# UPGRADE EFFECTS + CEILINGS
const STAGE1_CLAM_SLOTS: int = 3
const MAX_CLAM_SLOTS: int = 6
const MIN_GROWTH_TIME: float = 5.0
const GROWTH_SECONDS_PER_STACK: float = 2.0
const FLARE_MAX_RADIUS: float = 500.0
const FLARE_RADIUS_PER_STACK: float = 50.0
const CHUM_THRESHOLD_MAX: float = 7.0
const CHUM_THRESHOLD_PER_STACK: float = 0.5

# SAVING
const SAVE_PATH: String = "user://savegame.json"

# PLAYER STATE
var current_level: int = 1
var current_xp: int = 0
var money: float = 0.0
var sonar_ammo: int = 0
var held_pearls: Dictionary = {}
var owned_upgrades: Dictionary = {}
var pending_upgrades: Dictionary = {}

# computer at startup
var level_xp_thresholds: Array[int] = []
var loaded_clam_data: Dictionary = {}

func _ready() -> void:
	var cumulative: int = 0
	var xp_per_pearl_cycle: int = PLANT_XP + HARVEST_XP + SELL_XP_PER_PEARL
	for pearls_needed in LEVEL_PEARLS_REQUIRED:
		cumulative += pearls_needed * xp_per_pearl_cycle
		level_xp_thresholds.append(cumulative)

# --------------- XP FUNCTIONS ---------------

func award_xp(amount: int) -> void:
	current_xp += amount
	check_level_up()

func check_level_up() -> void:
	while current_xp >= get_xp_to_finish_level(current_level):
		current_level += 1
		grant_level_flares(current_level)
		refresh_clams()
		level_changed.emit(current_level)

# cumulative XP needed to go to next level
func get_xp_to_finish_level(level: int) -> int:
	if level - 1 < level_xp_thresholds.size():
		return level_xp_thresholds[level - 1]
	var total: int = level_xp_thresholds.back()
	for n in range(1, level - FREEPLAY_START_LEVEL + 2):
		total += get_freeplay_level_cost(n)
	return total

# total XP the player had when they reach a new level for XP bar
func get_xp_at_level_start(level: int) -> int:
	if level <= 1:
		return 0
	return get_xp_to_finish_level(level - 1)

func get_freeplay_level_cost(n: int) -> int:
	return int(FREEPLAY_BASE_XP + FREEPLAY_STEP * pow(float(n), 1.5))

# --------------- CLAM FUNCTIONS ---------------
func refresh_clams() -> void:
	var new_growth_time: float = get_growth_time_for_level(current_level)
	for clam in get_tree().get_nodes_in_group("clams"):
		clam.growth_time = new_growth_time
		clam.set_unlocked(is_clam_unlocked(clam))

func get_growth_time_for_level(level: int) -> float:
	var index: int = clamp(level - 1, 0, LEVEL_GROWTH_TIMES.size() - 1)
	var base_time: float = LEVEL_GROWTH_TIMES[index]
	var reduction: float = get_owned(UpgradeType.GROWTH_SPEED) * GROWTH_SECONDS_PER_STACK
	return max(base_time - reduction, min(base_time, MIN_GROWTH_TIME))

func is_clam_unlocked(clam: Node) -> bool:
	return current_level >= clam.unlock_level and get_owned(UpgradeType.CLAM_SLOT) >= clam.purchase_slot

# --------------- PEARL FUNCTIONS ---------------

func get_unlocked_pearl_types() -> Array:
	var result: Array = []
	for type in PEARL_DATA:
		if PEARL_DATA[type]["unlock_level"] <= current_level:
			result.append(type)
	return result

# get a random pearl type to grow
func roll_pearl_type() -> int:
	var unlocked: Array = get_unlocked_pearl_types()
	var total_weight: float = 0.0
	for type in unlocked:
		total_weight += PEARL_DATA[type]["weight"]
	var roll: float = randf() * total_weight
	for type in unlocked:
		roll -= PEARL_DATA[type]["weight"]
		if roll < 0.0:
			return type
	return unlocked.back()

func get_pearl_unlocked_at_level(level: int) -> int:
	for type in PEARL_DATA:
		if PEARL_DATA[type]["unlock_level"] == level:
			return type
	return -1

func get_pearl_texture(type: int) -> Texture2D:
	return PEARL_DATA[type]["texture"]

func collect_pearl(type: int) -> void:
	held_pearls[type] = held_pearls.get(type, 0) + 1
	print("Collected a ", PEARL_DATA[type]["name"])
	award_xp(HARVEST_XP)

func get_total_held_pearls() -> int:
	var total: int = 0
	for type in held_pearls:
		total += held_pearls[type]
	return total

func sell_all_pearls() -> float:
	if get_total_held_pearls() <= 0:
		return 0
	var earned_xp: int = 0
	var earned_money: float = 0.0
	for type in held_pearls:
		var count: int = held_pearls[type]
		earned_money += count * float(PEARL_DATA[type]["price"])
		earned_xp += count * int(PEARL_DATA[type]["xp"])
	held_pearls.clear()
	add_money(earned_money)
	award_xp(earned_xp)
	return earned_money

# --------------- MONEY & FLARE FUNCTIONS ---------------

func add_money(amount: float) -> void:
	money += amount
	money_changed.emit(money)

func grant_level_flares(level: int) -> void:
	if level == SONAR_UNLOCK_LEVEL:
		sonar_ammo += FLARES_ON_UNLOCK
	elif level > SONAR_UNLOCK_LEVEL:
		sonar_ammo += FLARES_PER_LEVEL

# returns true if a flare can be fired
func use_flare() -> bool:
	if Global.infinite_flares:
		return true
	if sonar_ammo <= 0:
		return false
	sonar_ammo -= 1
	return true

func buy_flare() -> bool:
	if money < FLARE_PRICE:
		return false
	add_money(-FLARE_PRICE)
	sonar_ammo += 1
	return true

func get_flare_radius() -> float:
	return FLARE_BASE_RADIUS + get_owned(UpgradeType.FLARE_RADIUS) * FLARE_RADIUS_PER_STACK

# --------------- CRAB FUNCTIONS ---------------

func get_crab_spawn_threshold() -> float:
	return Global.CRAB_SPAWN_THRESHOLD + get_owned(UpgradeType.CHUM_THRESHOLD) * CHUM_THRESHOLD_PER_STACK

func get_max_crabs() -> int:
	var extra: int = floori(float(current_level - FREEPLAY_START_LEVEL) / LEVELS_PER_EXTRA_CRAB)
	return BASE_MAX_CRABS + max(0, extra)

# --------------- UPGRADES ---------------

func get_owned(type: int) -> int:
	return owned_upgrades.get(type, 0)

func get_pending(type: int) -> int:
	return pending_upgrades.get(type, 0)

func get_upgrade_max_stacks(type: int) -> int:
	match type:
		UpgradeType.CLAM_SLOT:
			return MAX_CLAM_SLOTS - STAGE1_CLAM_SLOTS
		UpgradeType.GROWTH_SPEED:
			return int((LEVEL_GROWTH_TIMES.back() - MIN_GROWTH_TIME) / GROWTH_SECONDS_PER_STACK)
		UpgradeType.FLARE_RADIUS:
			return int((FLARE_MAX_RADIUS - FLARE_BASE_RADIUS) / FLARE_RADIUS_PER_STACK)
		UpgradeType.CHUM_THRESHOLD:
			return int((CHUM_THRESHOLD_MAX - Global.CRAB_SPAWN_THRESHOLD) / CHUM_THRESHOLD_PER_STACK)
	return 0

# determines if an offer can appear during level up
func can_offer_upgrade(type: int) -> bool:
	return get_owned(type) + get_pending(type) < get_upgrade_max_stacks(type)

# get up to 3 random distinct upgrade types that aren't maxed out
func roll_upgrade_choices(count: int = 3) -> Array:
	var pool: Array = []
	for type in UPGRADE_DATA:
		if can_offer_upgrade(type):
			pool.append(type)
	pool.shuffle()
	return pool.slice(0, count)

# scale the prices of upgrades depending on how many of the type you have
func get_upgrade_cost(type: int) -> int:
	var data: Dictionary = UPGRADE_DATA[type]
	return int(data["base_cost"] * pow(data["cost_multiplier"], get_owned(type)))

func can_buy_upgrade(type: int) -> bool:
	return get_owned(type) < get_upgrade_max_stacks(type) and money >= get_upgrade_cost(type)

func save_upgrade_for_later(type: int) -> void:
	pending_upgrades[type] = get_pending(type) + 1
	upgrades_changed.emit()

# from_pending is true when buying from available tab
func buy_upgrade(type: int, from_pending: bool) -> bool:
	if not can_buy_upgrade(type):
		return false
	if from_pending and get_pending(type) <= 0:
		return false
	add_money(-get_upgrade_cost(type))
	owned_upgrades[type] = get_owned(type) + 1
	if from_pending:
		pending_upgrades[type] = get_pending(type) - 1
	refresh_clams() # applies growth speed pr new clam slot
	upgrades_changed.emit()
	print("Bought upgrade: ", get_upgrade_name(type)) # TODO: change to a log print
	return true

func get_upgrade_name(type: int) -> String:
	return UPGRADE_DATA[type]["name"]

# get text for stacks of an upgrade
func get_upgrade_effect_text(type: int, stacks: int) -> String:
	match type:
		UpgradeType.CLAM_SLOT:
			return "+%d clam slot(s)" % stacks
		UpgradeType.GROWTH_SPEED:
			return "Growth time -%ss" % str(stacks * GROWTH_SECONDS_PER_STACK)
		UpgradeType.FLARE_RADIUS:
			return "Flare radius +%d" % int(stacks * FLARE_RADIUS_PER_STACK)
		UpgradeType.CHUM_THRESHOLD:
			return "Crab threshold +%s" % str(stacks * CHUM_THRESHOLD_PER_STACK)
	return ""

# --------------- TOOLS ---------------

func is_tool_unlocked(tool: Global.Tool) -> bool:
	match tool:
		Global.Tool.HAND:
			return true
		Global.Tool.BRUSH:
			return current_level >= 2
		Global.Tool.CHUM:
			return current_level >= 3
		Global.Tool.SONAR:
			return current_level >= SONAR_UNLOCK_LEVEL
		_:
			return false

# --------------- SAVE & LOAD ---------------
func to_dict() -> Dictionary:
	var clam_data: Dictionary = {}
	for clam in get_tree().get_nodes_in_group("clams"):
		clam_data[str(clam.name)] = clam.to_save_dict()
	return {
		"version": 1,
		"level": current_level,
		"xp": current_xp,
		"money": money,
		"sonar_ammo": sonar_ammo,
		"held_pearls": _keys_to_strings(held_pearls),
		"owned_upgrades": _keys_to_strings(owned_upgrades),
		"pending_upgrades": _keys_to_strings(pending_upgrades),
		"clams": clam_data,
	}

func from_dict(data: Dictionary) -> void:
	current_level = int(data.get("level", 1))
	current_xp = int(data.get("xp", 0))
	money = int(data.get("money", 0))
	sonar_ammo = int(data.get("sonar_ammo", 0))
	held_pearls = _keys_to_ints(data.get("held_pearls", {}))
	owned_upgrades = _keys_to_ints(data.get("owned_upgrades", {}))
	pending_upgrades = _keys_to_ints(data.get("pending_upgrades", {}))
	loaded_clam_data = data.get("clams", {})

func save_game() -> bool:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(to_dict(), "\t"))
	print("Game saved to ", ProjectSettings.globalize_path(SAVE_PATH))
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_game() -> bool:
	if not has_save():
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Save file is corrupted >:(")
		return false
	from_dict(data)
	Global.reset_run_state()
	get_tree().paused = false
	get_tree().reload_current_scene() # clams pick up their saved state in _ready
	return true

func take_loaded_clam_data(clam_name: String) -> Dictionary:
	if not loaded_clam_data.has(clam_name):
		return {}
	var data: Dictionary = loaded_clam_data[clam_name]
	loaded_clam_data.erase(clam_name)
	return data

func _keys_to_strings(dict: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key in dict:
		out[str(key)] = dict[key]
	return out

func _keys_to_ints(dict: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key in dict:
		out[int(key)] = int(dict[key])
	return out
