extends Area2D

var texture_empty = preload("res://assets/sprites/clam_empty_growing.png")
var texture_open = preload("res://assets/sprites/clam_ready_open.png")
var texture_dummy = preload("res://assets/sprites/pearl_dummy.png")
var texture_sediment = preload("res://assets/sprites/sediment_overlay.png")

enum State { EMPTY, GROWING, READY }
var current_state: State = State.EMPTY

const BAR_WIDTH: float = 100.0
const COLOR_GROWTH: Color = Color(0.2, 0.8, 0.2)
const COLOR_ATTACK: Color = Color(0.85, 0.15, 0.15)

# variables for crabs
signal state_changed(new_state: State)
var is_under_attack: bool = false
var attack_progress: float = 0.0
var attack_duration: float = Global.CRAB_ATTACK_DURATION

@export var growth_time: float = 10.0 # seconds to grow
@export var sediment_rate: float = 0.15 # rate at which sediment grows per second
@export var chum_boost: float = 3.0 # seconds cleared off the timer
@export var sediment_grace_period: float = 4.0 # seconds
@export var unlock_level: int = 1
@export var purchase_slot: int = 0 # 0 - unlocks only by level, N - unlocks with Nth new clam slot

var growth_progress: float = 0.0 # tracks accumulated growth seconds 0.0 to growth_time
var is_unlocked: bool = true
var sediment_level: float = 0.0 # 0.0 to 1.0
var sediment_grace_timer: float = 0.0
var pearl_type: int = -1 # rolled when pearl matures

@onready var clam_sprite: Sprite2D = $ClamSprite
@onready var pearl_sprite: Sprite2D = $PearlSprite
@onready var sediment_sprite: Sprite2D = $SedimentSprite
@onready var growth_bar_root: Node2D = $GrowthBarRoot
@onready var growth_bar_fill: ColorRect = $GrowthBarRoot/BarFill
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_event.connect(_on_input_event)
	growth_time = PlayerProgress.get_growth_time_for_level(PlayerProgress.current_level)
	set_unlocked(PlayerProgress.is_clam_unlocked(self))
	load_save_dict(PlayerProgress.take_loaded_clam_data(str(name)))
	update_visuals()
	update_sediment_visuals()

func _process(delta: float) -> void:
	if is_under_attack:
		attack_progress += delta
		update_attack_bar()
		return
	
	# only accumulate sediment and progress growth while GROWING
	if current_state == State.GROWING:
		if PlayerProgress.current_level >= 2:
			# dont accumulate sediment if just cleaned
			if sediment_grace_timer > 0.0:
				sediment_grace_timer -= delta
			# accumulate sediment over time
			elif sediment_level < 1.0:
				sediment_level += sediment_rate * delta
				sediment_level = clamp(sediment_level, 0.0, 1.0)
				update_sediment_visuals()
			
		# Slow down growth based on level
		# with level=1.0, pearls grows at 10%
		var growth_speed_multiplier: float = 1.0 - (sediment_level * 0.9) 
		
		# Advance the timer at reduced speed
		growth_progress += delta * growth_speed_multiplier
		
		# Check if growth target reached
		if growth_progress >= growth_time:
			mature_pearl()
		
		update_growth_bar()
	else:
		growth_bar_root.visible = false

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		match Global.active_tool:
			Global.Tool.HAND:
				handle_hand_tool()
			Global.Tool.BRUSH:
				handle_brush_tool()
			Global.Tool.CHUM:
				handle_chum_tool()

func set_unlocked(unlocked: bool) -> void:
	is_unlocked = unlocked
	visible = unlocked
	input_pickable = unlocked
	collision_shape.disabled = not unlocked

func handle_hand_tool() -> void:
	match current_state:
		State.EMPTY:
			plant_dummy()
		State.READY:
			harvest_pearl()
		State.GROWING:
			print("Pearl is still growing!") #TODO: change to a screen print

func handle_brush_tool() -> void:
	if sediment_level > 0.1:
		scrub_sediment()
	else:
		print("Clam is already clean!") #TODO: change to a screen print

func handle_chum_tool() -> void:
	if current_state == State.GROWING:
		if Global.instant_chum:
			growth_progress = growth_time
		else:
			growth_progress += chum_boost
		growth_progress = clamp(growth_progress, 0.0, growth_time)
		Global.add_chum_heat() # fill up chum gauge
		PlayerProgress.award_xp(PlayerProgress.CHUM_XP)
		print("Applied Chum. Growth progress: ", snapped(growth_progress, 0.1), " / ", growth_time, "s")
		
		# growth guard
		if growth_progress >= growth_time:
			mature_pearl()
	else:
		print("Chum can only be used on growing clams!")

func plant_dummy() -> void:
	current_state = State.GROWING
	growth_progress = 0.0
	sediment_level = 0.0
	pearl_type = -1
	sediment_grace_timer = sediment_grace_period
	update_visuals()
	update_sediment_visuals()
	PlayerProgress.award_xp(PlayerProgress.PLANT_XP)
	print("Planted pearl dummy!")

func mature_pearl() -> void:
	current_state = State.READY
	pearl_type = PlayerProgress.roll_pearl_type()
	update_visuals()

func harvest_pearl() -> void:
	var harvested_type: int = pearl_type
	current_state = State.EMPTY
	growth_progress = 0.0
	sediment_level = 0.0
	pearl_type = -1
	update_visuals()
	update_sediment_visuals()
	PlayerProgress.collect_pearl(harvested_type)
	print("Pearl harvested!")

func scrub_sediment() -> void:
	if Global.instant_clean:
		sediment_level = 0.0
	else:
		sediment_level -= 0.5
	sediment_level = clamp(sediment_level, 0.0, 1.0)
	if sediment_level <= 0.0:
		sediment_grace_timer = sediment_grace_period
	update_sediment_visuals()
	print("Scrubbed clam! Current sediment: ", sediment_level)

func start_attack(duration: float) -> void:
	is_under_attack = true
	attack_progress = 0.0
	attack_duration = duration
	print("A crab is attacking the clam!")

func end_attack_success() -> void:
	current_state = State.EMPTY
	growth_progress = 0.0
	sediment_level = 0.0
	pearl_type = -1
	is_under_attack = false
	growth_bar_root.visible = false
	update_visuals()
	update_sediment_visuals()
	print("Crab is destroyed the pearl! Clam is empty again :(")

func end_attack_cancelled() -> void:
	is_under_attack = false
	print("Crab was scared off!")

func update_visuals() -> void:
	state_changed.emit(current_state) # let the crabs know what's up
	match current_state:
		State.EMPTY:
			clam_sprite.texture = texture_empty
			pearl_sprite.visible = false
		State.GROWING:
			clam_sprite.texture = texture_empty
			pearl_sprite.texture = texture_dummy
			pearl_sprite.visible = true
		State.READY:
			if pearl_type < 0: # backup check
				pearl_type = PlayerProgress.roll_pearl_type()
			clam_sprite.texture = texture_open
			pearl_sprite.texture = PlayerProgress.get_pearl_texture(pearl_type)
			pearl_sprite.visible = true

func update_sediment_visuals() -> void:
	# hide sediment when EMPTY or READY, or when scrubbed
	if current_state == State.GROWING and sediment_level > 0.1:
		sediment_sprite.visible = true
		sediment_sprite.modulate.a = sediment_level
	else:
		sediment_sprite.visible = false

func update_growth_bar() -> void:
	growth_bar_root.visible = true
	growth_bar_fill.color = COLOR_GROWTH
	var fraction: float = clamp(growth_progress / growth_time, 0.0, 1.0)
	growth_bar_fill.size.x = BAR_WIDTH * fraction

func update_attack_bar() -> void:
	growth_bar_root.visible = true
	growth_bar_fill.color = COLOR_ATTACK
	var fraction: float = clamp(attack_progress / attack_duration, 0.0, 1.0)
	growth_bar_fill.size.x = BAR_WIDTH * fraction

# ---------------- SAVE & LOAD ----------------

func to_save_dict() -> Dictionary:
	return {
		"state": current_state,
		"growth_progress": growth_progress,
		"sediment_level": sediment_level,
		"pearl_type": pearl_type,
	}

func load_save_dict(data: Dictionary) -> void:
	if data.is_empty():
		return
	current_state = int(data.get("state", State.EMPTY)) as State
	growth_progress = float(data.get("growth_progress", 0.0))
	sediment_level = float(data.get("sediment_level", 0.0))
	pearl_type = int(data.get("pearl_type", -1))
