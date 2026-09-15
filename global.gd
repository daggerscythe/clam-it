extends Node

# PLAYER TOOLS
enum Tool { HAND, BRUSH, CHUM, SONAR }
var active_tool: Tool = Tool.HAND

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("HAND_SELECT"):
		active_tool = Tool.HAND
		print("Active Tool: HAND")
	elif Input.is_action_just_pressed("BRUSH_SELECT"):
		active_tool = Tool.BRUSH
		print("Active Tool: BRUSH")
	elif Input.is_action_just_pressed("CHUM_SELECT"):
		active_tool = Tool.CHUM
		print("Active Tool: CHUM")
	elif Input.is_action_just_pressed("SONAR_SELECT"):
		active_tool = Tool.SONAR
		print("Active Tool: SONAR")
