extends Node

# PLAYER TOOLS
enum Tool { HAND, BRUSH, CHUM, SONAR }
var active_tool: Tool = Tool.HAND
const CURSOR_HAND: Texture2D = preload("res://assets/sprites/hand.png")
const CURSOR_BRUSH: Texture2D = preload("res://assets/sprites/brush.png")
const CURSOR_CHUM: Texture2D = preload("res://assets/sprites/chum.png")
const CURSOR_SONAR: Texture2D = preload("res://assets/sprites/sonic_flare_icon.png")

# GAME CONSTANTS
const CHUM_METER_MAX: float = 10.0
const CRAB_SPAWN_THRESHOLD: float = 4.0
const CRAB_ATTACK_DURATION: float = 2.0
const CHUM_PER_USE: float = 1.0
const METER_DECAY_RATE: float = 0.2
const MAX_CRABS: int = 4

# SPAWN AREA BOUNDS
const WATER_TOP_Y: float = 220.0
const WATER_BOTTOM_Y: float = 1050.0
const SPAWN_MARGIN_X: float = 40.0
const SCREEN_WIDTH: float = 1920.0

# HOW FAST CRABS SPAWN
const SPAWN_INTERVAL_MAX: float = 6.0
const SPAWN_INTERVAL_MIN: float = 1.5
const CRAB_SCENE: PackedScene = preload("res://scenes/crab.tscn")

# CRAB + CHUM + SONAR VARIABLES
var chum_meter: float = 0.0
var crab_counter: int = 0
var sonar_ammo: int = 4 # can probably be upgraded with XP or money
var spawn_timer: float = 0.0

func _ready() -> void:
	set_cursor_for_tool()

func _process(delta: float) -> void:
	# Drain chum meter over time
	if chum_meter > 0.0:
		chum_meter -= METER_DECAY_RATE * delta
		chum_meter = clamp(chum_meter, 0.0, CHUM_METER_MAX)
	
	# Count down toward the next spawn
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = get_spawn_interval()
		if PlayerProgress.current_level >= 4 and chum_meter >= CRAB_SPAWN_THRESHOLD and crab_counter < MAX_CRABS:
			try_spawn_crab()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("HAND_SELECT"):
		active_tool = Tool.HAND
		set_cursor_for_tool()
	elif Input.is_action_just_pressed("BRUSH_SELECT"):
		if PlayerProgress.is_tool_unlocked(Global.Tool.BRUSH):
			active_tool = Tool.BRUSH
			set_cursor_for_tool()
		else:
			print("Brush not unlocked yet.")
	elif Input.is_action_just_pressed("CHUM_SELECT"):
		if PlayerProgress.is_tool_unlocked(Global.Tool.CHUM):
			active_tool = Tool.CHUM
			set_cursor_for_tool()
		else:
			print("Chum not unlocked yet.")
	elif Input.is_action_just_pressed("SONAR_SELECT"):
		if PlayerProgress.is_tool_unlocked(Global.Tool.SONAR):
			active_tool = Tool.SONAR
			set_cursor_for_tool()
		else: 
			print("Sonar not unlocked yet.")

func set_cursor_for_tool() -> void:
	var texture: Texture2D
	match active_tool:
		Tool.HAND:
			texture = CURSOR_HAND
		Tool.BRUSH:
			texture = CURSOR_BRUSH
		Tool.CHUM:
			texture = CURSOR_CHUM
		Tool.SONAR:
			texture = CURSOR_SONAR
	Input.set_custom_mouse_cursor(texture, Input.CURSOR_ARROW, texture.get_size() / 2)

func add_chum_heat() -> void:
	chum_meter += CHUM_PER_USE
	chum_meter = clamp(chum_meter, 0.0, CHUM_METER_MAX)

func get_spawn_interval() -> float:
	# the higher the meter = shorter spawn interval = faster spawns
	# 0.0 is at crab spawn threshold, 1.0 at full gauge
	var t: float = clamp((chum_meter - CRAB_SPAWN_THRESHOLD) / (CHUM_METER_MAX - CRAB_SPAWN_THRESHOLD), 0.0, 1.0)
	return lerp(SPAWN_INTERVAL_MAX, SPAWN_INTERVAL_MIN, t)

func try_spawn_crab() -> void:
	# don't spawn if no pearls growing
	var has_growing_clam: bool = false
	for clam in get_tree().get_nodes_in_group("clams"):
		if clam.current_state == clam.State.GROWING:
			has_growing_clam = true
			break
	if not has_growing_clam:
		return
	
	var crab = CRAB_SCENE.instantiate()
	get_tree().current_scene.add_child(crab)
	crab.global_position = get_random_spawn_position()
	crab_counter += 1

func get_random_spawn_position() -> Vector2:
	var y: float = randf_range(WATER_TOP_Y, WATER_BOTTOM_Y)
	# 50-50 chance as to what side it spawns from
	var x: float = -SPAWN_MARGIN_X if randi() % 2 == 0 else SCREEN_WIDTH + SPAWN_MARGIN_X
	return Vector2(x, y)

func on_crab_removed() -> void:
	crab_counter -= 1
	crab_counter = max(crab_counter, 0)
