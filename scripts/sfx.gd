extends Node

const SELECT: AudioStream = preload("res://assets/audio/select.mp3")
const COLLECT: AudioStream = preload("res://assets/audio/collect.mp3")
const DESTROY: AudioStream = preload("res://assets/audio/destroy.mp3")
const CRAB_WALK: AudioStream = preload("res://assets/audio/crab_walk.mp3")

const SFX_VOLUME_DB: float = 0.0
const CRAB_WALK_VOLUME_DB: float = -8.0 # the loop is quieter
const POOL_SIZE: int = 6 # how many one-shot sounds can overlap

var pool: Array[AudioStreamPlayer] = []
var crab_walk_player: AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# ensure UI clicks still make sound when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	for i in POOL_SIZE:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(player)
		pool.append(player)
	
	crab_walk_player = AudioStreamPlayer.new()
	crab_walk_player.stream = CRAB_WALK
	crab_walk_player.stream.loop = true
	crab_walk_player.volume_db = CRAB_WALK_VOLUME_DB
	add_child(crab_walk_player)
	
	# every button in the game plays select sound
	get_tree().node_added.connect(_on_node_added)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var any_walking: bool = false
	if not get_tree().paused:
		for crab in get_tree().get_nodes_in_group("crabs"):
			if crab.is_walking():
				any_walking = true
				break
	if any_walking and not crab_walk_player.playing:
		crab_walk_player.play()
	elif not any_walking and crab_walk_player.playing:
		crab_walk_player.stop()

# for UI button sounds
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(play_select)

func play(stream: AudioStream, volume_db: float = SFX_VOLUME_DB) -> void:
	for player in pool:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.play()
			return
	# restart first player if all are busy
	pool[0].stream = stream
	pool[0].play()

func play_select() -> void:
	play(SELECT)

func play_collect() -> void:
	play(COLLECT)

func play_destroy() -> void:
	play(DESTROY)
