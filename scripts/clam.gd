extends Area2D

var texture_empty = preload("res://assets/sprites/clam_empty_growing.png")
var texture_open = preload("res://assets/sprites/clam_ready_open.png")
var texture_dummy = preload("res://assets/sprites/pearl_dummy.png")
var texture_mature = preload("res://assets/sprites/mature_pearl.png")
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
var attack_duration: float = 2.0

@export var growth_time: float = 10.0 # seconds to grow
@export var sediment_rate: float = 0.15 # rate at which sediment grows per second
@export var chum_boost: float = 1.0 # seconds cleared off the timer

var growth_progress: float = 0.0 # tracks accumulated growth seconds 0.0 to growth_time
var sediment_level: float = 0.0 # 0.0 to 1.0

@onready var clam_sprite: Sprite2D = $ClamSprite
@onready var pearl_sprite: Sprite2D = $PearlSprite
@onready var sediment_sprite: Sprite2D = $SedimentSprite
@onready var growth_bar_root: Node2D = $GrowthBarRoot
@onready var growth_bar_fill: ColorRect = $GrowthBarRoot/BarFill


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_event.connect(_on_input_event)
	update_visuals()

func _process(delta: float) -> void:
	if is_under_attack:
		attack_progress += delta
		update_attack_bar()
		return
	
	# Only accumulate sediment and progress growth while GROWING and not being attacked
	if current_state == State.GROWING and not is_under_attack:
		# Accumulate sediment over time
		if sediment_level < 1.0:
			sediment_level += sediment_rate * delta
			sediment_level = clamp(sediment_level, 0.0, 1.0)
			update_sediment_visuals()
			
		# Slow down growth based on level
		var growth_speed_multiplier: float = 1.0 - (sediment_level * 0.9) # with level=1.0, pearls grows at 10%
		
		# Advance the timer at reduced speed
		growth_progress += delta * growth_speed_multiplier
		
		# Check if growth target reached
		if growth_progress >= growth_time:
			current_state = State.READY
			update_visuals()
		
		update_growth_bar()
	else:
		growth_bar_root.visible = false

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# Check for left mouse click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Match the tool being used
		match Global.active_tool:
			Global.Tool.HAND:
				handle_hand_tool()
			Global.Tool.BRUSH:
				handle_brush_tool()
			Global.Tool.CHUM:
				handle_chum_tool()

func handle_hand_tool() -> void:
	match current_state:
		State.EMPTY:
			plant_dummy()
		State.READY:
			harvest_pearl()
		State.GROWING:
			print("Pearl is still growing!")

func handle_brush_tool() -> void:
	if sediment_level > 0.1:
		scrub_sediment()
	else:
		print("Clam is already clean!")

func handle_chum_tool() -> void:
	if current_state == State.GROWING:
		growth_progress += chum_boost
		growth_progress = clamp(growth_progress, 0.0, growth_time)
		Global.add_chum_heat() # fill up chum gauge
		print("Applied Chum. Growth progress: ", snapped(growth_progress, 0.1), " / ", growth_time, "s")
		
		# growth guard
		if growth_progress >= growth_time:
			current_state = State.READY
			update_visuals()
	else:
		print("Chum can only be used on growing clams!")

func plant_dummy() -> void:
	current_state = State.GROWING
	growth_progress = 0.0
	sediment_level = 0.0
	update_visuals()
	update_sediment_visuals()
	print("Planted pearl dummy!")

func harvest_pearl() -> void:
	current_state = State.EMPTY
	growth_progress = 0.0
	sediment_level = 0.0
	update_visuals()
	update_sediment_visuals()
	# Emit a signal here later to give XP and money
	print("Pearl harvested!")

func scrub_sediment() -> void:
	# Reduce seciment by 50% when clicked
	sediment_level -= 0.2
	sediment_level = clamp(sediment_level, 0.0, 1.0)
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
			clam_sprite.texture = texture_open
			pearl_sprite.texture = texture_mature
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
