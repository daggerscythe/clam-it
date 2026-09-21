extends Node

@onready var count_label: Label = $PearlIcon/CountLabel

func _process(_delta: float) -> void:
	count_label.text = str(PlayerProgress.held_pearls)
