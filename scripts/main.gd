extends Node2D

const FLARE_RADIUS: float = 250.0

func _unhandled_input(event: InputEvent) -> void:
	if Global.active_tool == Global.Tool.SONAR and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			fire_sonic_flare(get_global_mouse_position())

func fire_sonic_flare(click_position: Vector2) -> void:
	if Global.sonar_ammo <= 0:
		print("Out of sonic flares!")
		return
	
	Global.sonar_ammo -= 1
	var scared_count: int = 0
	for crab in get_tree().get_nodes_in_group("crabs"):
		if crab.global_position.distance_to(click_position) <= FLARE_RADIUS:
			crab.scare_off()
			scared_count += 1
	print("Sonic flare scared off ", scared_count, " crabs! Ammo left: ", Global.sonar_ammo)
