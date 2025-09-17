extends Control
class_name shop

@onready var play: Button = $play
@onready var upgrade: Button = $upgrade
@onready var upgrade_title: Label = $upgradeTitle
@onready var upgrade_description: Label = $upgradeDescription
@onready var car_type_selector: Button = $VBoxContainer/carTypeSelector
@onready var engine_type_selector: Button = $VBoxContainer/engineTypeSelector
@onready var fling_type_selector: Button = $VBoxContainer/flingTypeSelector
@onready var money: Label = $money

var current_car_level = 0
var current_engine_level = 0
var current_fling_level = 0

func get_car_stats_for_level(level: int):
	return {
		"max_speed_multiplier": 1.0 + (level * 0.2),
		"acceleration_multiplier": 1.0 + (level * 0.15),
		"handling_multiplier": 1.0 + (level * 0.1),
		"cost": get_upgrade_cost(level, "car")
	}

func get_engine_stats_for_level(level: int):
	return {
		"torque_multiplier": 1.0 + (level * 0.3),
		"efficiency_multiplier": 1.0 + (level * 0.2),
		"cost": get_upgrade_cost(level, "engine")
	}

func get_fling_stats_for_level(level: int):
	return {
		"force_multiplier": 1.0 + (level * 0.25),
		"cooldown_reduction": level * 8.0,
		"duration_multiplier": 1.0 + (level * 0.15),
		"cost": get_upgrade_cost(level, "fling")
	}

func get_upgrade_cost(level: int, type: String):
	if level == 0:
		return 0
	
	var base_cost = 500
	match type:
		"car":
			base_cost = 800
		"engine":
			base_cost = 600
		"fling":
			base_cost = 400
	
	return int(base_cost * pow(1.5, level - 1))

var current_upgrade_category = "car"

var player_money = 5000
var return_position = Vector3.ZERO
var return_rotation = Vector3.ZERO
var shop_distance = 0.0

func _ready():
	load_upgrades()

	if globals.has_method("get_return_position"):
		return_position = globals.get_return_position()
	if globals.has_method("get_return_rotation"):
		return_rotation = globals.get_return_rotation()

	shop_distance = globals.distance

	var distance_money = int(shop_distance / 100.0)
	player_money += distance_money
	print("Awarded $", distance_money, " for traveling ", shop_distance, " meters!")

	if play:
		play.pressed.connect(_on_play_pressed)
	if car_type_selector:
		car_type_selector.pressed.connect(_on_car_type_pressed)
	if engine_type_selector:
		engine_type_selector.pressed.connect(_on_engine_type_pressed)
	if fling_type_selector:
		fling_type_selector.pressed.connect(_on_fling_type_pressed)
	if upgrade:
		upgrade.pressed.connect(_on_upgrade_pressed)

	update_ui()

func _on_play_pressed():
	save_upgrades()

	if globals.has_method("set_return_data"):
		globals.set_return_data(return_position, return_rotation, shop_distance)
	else:
		globals.return_position = return_position
		globals.return_rotation = return_rotation
		globals.return_distance = shop_distance

	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_car_type_pressed():
	current_upgrade_category = "car"
	update_upgrade_display()

func _on_engine_type_pressed():
	current_upgrade_category = "engine"
	update_upgrade_display()

func _on_fling_type_pressed():
	current_upgrade_category = "fling"
	update_upgrade_display()

func _on_upgrade_pressed():
	var next_level
	var upgrade_stats
	
	match current_upgrade_category:
		"car":
			next_level = current_car_level + 1
			upgrade_stats = get_car_stats_for_level(next_level)
		"engine":
			next_level = current_engine_level + 1
			upgrade_stats = get_engine_stats_for_level(next_level)
		"fling":
			next_level = current_fling_level + 1
			upgrade_stats = get_fling_stats_for_level(next_level)

	if upgrade_stats.cost <= player_money:
		match current_upgrade_category:
			"car":
				current_car_level += 1
			"engine":
				current_engine_level += 1
			"fling":
				current_fling_level += 1

		player_money -= upgrade_stats.cost
		update_ui()
		update_upgrade_display()
		print("Upgraded ", current_upgrade_category, " to level ", next_level)
	else:
		print("Not enough money! Need: $", upgrade_stats.cost)

func update_ui():
	if car_type_selector:
		var car_stats = get_car_stats_for_level(current_car_level)
		car_type_selector.text = "Car: %.1fx Speed, %.1fx Accel" % [car_stats.max_speed_multiplier, car_stats.acceleration_multiplier]

	if engine_type_selector:
		var engine_stats = get_engine_stats_for_level(current_engine_level)
		engine_type_selector.text = "Engine: %.1fx Torque, %.1fx Efficiency" % [engine_stats.torque_multiplier, engine_stats.efficiency_multiplier]

	if fling_type_selector:
		var fling_stats = get_fling_stats_for_level(current_fling_level)
		fling_type_selector.text = "Fling: %.1fx Force, -%.0fs Cooldown" % [fling_stats.force_multiplier, fling_stats.cooldown_reduction]

	if money:
		money.text = "$" + str(player_money)

func update_upgrade_display():
	var next_level
	var current_stats
	var next_stats
	
	match current_upgrade_category:
		"car":
			next_level = current_car_level + 1
			current_stats = get_car_stats_for_level(current_car_level)
			next_stats = get_car_stats_for_level(next_level)
		"engine":
			next_level = current_engine_level + 1
			current_stats = get_engine_stats_for_level(current_engine_level)
			next_stats = get_engine_stats_for_level(next_level)
		"fling":
			next_level = current_fling_level + 1
			current_stats = get_fling_stats_for_level(current_fling_level)
			next_stats = get_fling_stats_for_level(next_level)

	if upgrade_title:
		upgrade_title.text = current_upgrade_category.capitalize() + " Upgrade"

	if upgrade_description:
		var description_text = "Current Level: " + str(current_level_for_category()) + "\n"
		description_text += "Next Level: " + str(next_level) + "\n\n"
		
		match current_upgrade_category:
			"car":
				description_text += "Speed: %.1fx → %.1fx (+%.1fx)\n" % [current_stats.max_speed_multiplier, next_stats.max_speed_multiplier, next_stats.max_speed_multiplier - current_stats.max_speed_multiplier]
				description_text += "Acceleration: %.1fx → %.1fx (+%.1fx)\n" % [current_stats.acceleration_multiplier, next_stats.acceleration_multiplier, next_stats.acceleration_multiplier - current_stats.acceleration_multiplier]
				description_text += "Handling: %.1fx → %.1fx (+%.1fx)\n" % [current_stats.handling_multiplier, next_stats.handling_multiplier, next_stats.handling_multiplier - current_stats.handling_multiplier]
			"engine":
				description_text += "Torque: %.1fx → %.1fx (+%.1fx)\n" % [current_stats.torque_multiplier, next_stats.torque_multiplier, next_stats.torque_multiplier - current_stats.torque_multiplier]
				description_text += "Efficiency: %.1fx → %.1fx (+%.1fx)\n" % [current_stats.efficiency_multiplier, next_stats.efficiency_multiplier, next_stats.efficiency_multiplier - current_stats.efficiency_multiplier]
			"fling":
				description_text += "Force: %.1fx → %.1fx (+%.1fx)\n" % [current_stats.force_multiplier, next_stats.force_multiplier, next_stats.force_multiplier - current_stats.force_multiplier]
				description_text += "Cooldown Reduction: %.0fs → %.0fs (+%.0fs)\n" % [current_stats.cooldown_reduction, next_stats.cooldown_reduction, next_stats.cooldown_reduction - current_stats.cooldown_reduction]
				description_text += "Duration: %.1fx → %.1fx (+%.1fx)\n" % [current_stats.duration_multiplier, next_stats.duration_multiplier, next_stats.duration_multiplier - current_stats.duration_multiplier]
		
		description_text += "\nCost: $" + str(next_stats.cost)
		upgrade_description.text = description_text

func current_level_for_category():
	match current_upgrade_category:
		"car":
			return current_car_level
		"engine":
			return current_engine_level
		"fling":
			return current_fling_level
	return 0

func get_car_stats():
	return get_car_stats_for_level(current_car_level)

func get_engine_stats():
	return get_engine_stats_for_level(current_engine_level)

func get_fling_stats():
	return get_fling_stats_for_level(current_fling_level)

func add_money(amount: int):
	player_money += amount
	update_ui()

func save_upgrades():
	var save_data = {
		"car_level": current_car_level,
		"engine_level": current_engine_level,
		"fling_level": current_fling_level,
		"money": player_money
	}
	globals.save_upgrade_data(save_data)

func load_upgrades():
	var save_data = globals.load_upgrade_data()
	if save_data:
		current_car_level = save_data.get("car_level", 0)
		current_engine_level = save_data.get("engine_level", 0)
		current_fling_level = save_data.get("fling_level", 0)
		player_money = save_data.get("money", 5000)
