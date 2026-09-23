extends PanelContainer

@onready var messages: RichTextLabel = $Messages

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	messages.bbcode_enabled = true
	messages.scroll_following = true
	messages.get_v_scroll_bar().modulate.a = 0.0 # hide scroll bar
	for line in GameLog.history:
		messages.append_text(line + "\n")
	GameLog.message_added.connect(_on_message_added)

func _on_message_added(line: String) -> void:
	messages.append_text(line + "\n")
	while messages.get_paragraph_count() > GameLog.MAX_MESSAGES:
		messages.remove_paragraph(0)
