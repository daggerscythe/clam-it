extends Node

@onready var count_label: Label = $PearlIcon/CountLabel

func _process(_delta: float) -> void:
	count_label.text = str(PlayerProgress.get_total_held_pearls())
