extends Control

const INTRO_TITLE: String = "Welcome to Clam It!"
const INTRO_TEXT: String = """You run a pearl farm on the sea floor. Here's how to grow your first pearl:

1. PLANT: With the Hand tool (press 1 or H), click the empty clam to plant a pearl dummy.

2. WAIT: The green bar above the clam shows how close the pearl is to being ready.

3. HARVEST: When the clam opens and shows a pearl, click it with the Hand tool to collect it.

4. SELL: Click the dock at the top of the screen to sell your pearls for money and XP.

Level up to unlock new tools and more clams. Good luck!"""

@onready var title_label: Label = $TitleLabel
@onready var body_label: Label = $BodyLabel
@onready var start_button: Button = $StartButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	title_label.text = INTRO_TITLE
	body_label.text = INTRO_TEXT
	start_button.pressed.connect(_on_start_pressed)
	
	# only once per launch; loading a save reloads the scene but shouldn't show this again
	if PlayerProgress.has_seen_intro:
		visible = false
		return
	PlayerProgress.has_seen_intro = true
	visible = true
	get_tree().paused = true

func _on_start_pressed() -> void:
	visible = false
	get_tree().paused = false
	GameLog.info("Click the empty clam with the Hand tool to plant your first pearl!")
