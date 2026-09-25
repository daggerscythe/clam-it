extends Area2D

enum CrabState { SEEKING, ATTACKING, FLEEING }
var state: CrabState = CrabState.SEEKING

@onready var sprite: AnimatedSprite2D = $CrabSprite

# CRAB CONSTANTS
const SPEED: float = 100.0
const FLEE_SPEED_MULTIPLIER: float = 2.0
const STOP_DISTANCE: float = 55.0

var target_clam: Node = null
var attack_timer: float = 0.0
var flee_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	find_target()

func _process(delta: float) -> void:
	match state:
		CrabState.SEEKING:
			_process_seeking(delta)
		CrabState.ATTACKING:
			_process_attacking(delta)
		CrabState.FLEEING:
			_process_fleeing(delta)

# Find new target if pearl is harvested from clam prior to attack
func _on_target_state_changed(new_state) -> void:
	if new_state != target_clam.State.EMPTY:
		return
	if state == CrabState.ATTACKING:
		target_clam.end_attack_cancelled()
	find_target()

func _process_seeking(delta: float) -> void:
	if target_clam == null:
		start_fleeing()
		return
	var to_target: Vector2 = target_clam.global_position - global_position
	if to_target.length() <= STOP_DISTANCE:
		start_attacking()
	else:
		global_position += to_target.normalized() * SPEED * delta

func _process_attacking(delta: float) -> void:
	attack_timer += delta
	if attack_timer >= Global.CRAB_ATTACK_DURATION:
		# disconnect from target's signal so the destruction of pearl doesn't interrupt attack
		var clam_plundered: Node = target_clam
		start_fleeing()
		clam_plundered.end_attack_success()

func _process_fleeing(delta: float) -> void:
	global_position += flee_direction * SPEED * FLEE_SPEED_MULTIPLIER * delta
	if global_position.x < -100 or global_position.x > 2020:
		Global.on_crab_removed()
		queue_free()

# Path finding function to find a random clam with a pearl
func find_target() -> void:
	if target_clam and target_clam.state_changed.is_connected(_on_target_state_changed):
		target_clam.state_changed.disconnect(_on_target_state_changed)
	
	var candidates: Array = []
	for clam in get_tree().get_nodes_in_group("clams"):
		if clam.is_crab_target():
			candidates.append(clam)
	
	if candidates.is_empty():
		start_fleeing()
		return
	
	target_clam = candidates.pick_random()
	target_clam.state_changed.connect(_on_target_state_changed)
	state = CrabState.SEEKING
	sprite.play("walk")

func start_attacking() -> void:
	state = CrabState.ATTACKING
	attack_timer = 0.0
	target_clam.start_attack(Global.CRAB_ATTACK_DURATION)
	sprite.play("idle")

func start_fleeing() -> void:
	state = CrabState.FLEEING
	if target_clam:
		flee_direction = (global_position - target_clam.global_position).normalized()
		if target_clam.state_changed.is_connected(_on_target_state_changed):
			target_clam.state_changed.disconnect(_on_target_state_changed)
	if flee_direction == Vector2.ZERO:
		flee_direction = Vector2.RIGHT if global_position.x > 960 else Vector2.LEFT
	sprite.play("walk")

func scare_off() -> void:
	if state == CrabState.FLEEING:
		return
	if state == CrabState.ATTACKING:
		var clam_spared: Node = target_clam
		start_fleeing()
		clam_spared.end_attack_cancelled()
	else:
		start_fleeing()

func is_walking() -> bool:
	return state != CrabState.ATTACKING
