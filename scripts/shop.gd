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

var car_upgrades = {
	"basic": {
		"name": "Basic Car",
		"description": "(Helvetica) Standard vehicle with basic performance",
		"max_speed_multiplier": 1.0,
		"acceleration_multiplier": 1.0,
		"handling_multiplier": 1.0,
		"cost": 0
	},
	"sport": {
		"name": "Sport Car", 
		"description": "good speed amount",
		"max_speed_multiplier": 1.3,
		"acceleration_multiplier": 1.2,
		"handling_multiplier": 1.1,
		"cost": 1000
	},
	"racing": {
		"name": "Racing Car",
		"description": "now thats a lot of damage",
		"max_speed_multiplier": 1.6,
		"acceleration_multiplier": 1.5,
		"handling_multiplier": 1.3,
		"cost": 2500
	}
}

var engine_upgrades = {
	"stock": {
		"name": "Stock Engine",
		"description": "(Helvetica) Standard engine performance",
		"torque_multiplier": 1.0,
		"efficiency_multiplier": 1.0,
		"cost": 0
	},
	"turbo": {
		"name": "Turbo Engine",
		"description": "torque and power",
		"torque_multiplier": 1.4,
		"efficiency_multiplier": 1.2,
		"cost": 800
	},
	"supercharged": {
		"name": "Supercharged Engine",
		"description": "maximum efficiency or something",
		"torque_multiplier": 1.8,
		"efficiency_multiplier": 1.5,
		"cost": 1500
	}
}

var fling_upgrades = {
	"basic": {
		"name": "Basic Fling",
		"description": "(Helvetica) Standard fling ability",
		"force_multiplier": 1.0,
		"cooldown_reduction": 0.0,
		"duration_multiplier": 1.0,
		"cost": 0
	},
	"enhanced": {
		"name": "Enhanced Fling",
		"description": "stonk fling with faster cooldown",
		"force_multiplier": 1.3,
		"cooldown_reduction": 10.0,
		"duration_multiplier": 1.2,
		"cost": 600
	},
	"ultimate": {
		"name": "Ultimate Fling",
		"description": "learn to fly omega upgrade",
		"force_multiplier": 1.6,
		"cooldown_reduction": 20.0,
		"duration_multiplier": 1.5,
		"cost": 1200
	}
}

var selected_car_type = "basic"
var selected_engine_type = "stock"
var selected_fling_type = "basic"

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

	var distance_money = int(shop_distance / 10.0)
	player_money += distance_money
	print("Awarded $", distance_money, " for traveling ", shop_distance, " meters!")

	globals.upgrade_data.money = player_money
	globals.save_upgrade_data()

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
	show_upgrade_menu("car")

func _on_engine_type_pressed():
	show_upgrade_menu("engine")

func _on_fling_type_pressed():
	show_upgrade_menu("fling")

func show_upgrade_menu(upgrade_type: String):
	var upgrades_dict
	var current_selection

	match upgrade_type:
		"car":
			upgrades_dict = car_upgrades
			current_selection = selected_car_type
		"engine":
			upgrades_dict = engine_upgrades
			current_selection = selected_engine_type
		"fling":
			upgrades_dict = fling_upgrades
			current_selection = selected_fling_type

	var keys = upgrades_dict.keys()
	var next_index = (keys.find(current_selection) + 1) % keys.size()
	var next_upgrade = keys[next_index]

	if upgrades_dict[next_upgrade].cost <= player_money:
		match upgrade_type:
			"car":
				selected_car_type = next_upgrade
			"engine":
				selected_engine_type = next_upgrade
			"fling":
				selected_fling_type = next_upgrade

		player_money -= upgrades_dict[next_upgrade].cost
		update_ui()
		print("Upgraded to: ", upgrades_dict[next_upgrade].name)
	else:
		print("Not enough money! Need: ", upgrades_dict[next_upgrade].cost)

func _on_upgrade_pressed():
	update_upgrade_info()

func update_ui():

	if car_type_selector:
		var car_stats = car_upgrades[selected_car_type]
		car_type_selector.text = "Car: %.1fx Speed, %.1fx Accel" % [car_stats.max_speed_multiplier, car_stats.acceleration_multiplier]

	if engine_type_selector:
		var engine_stats = engine_upgrades[selected_engine_type]
		engine_type_selector.text = "Engine: %.1fx Torque, %.1fx Efficiency" % [engine_stats.torque_multiplier, engine_stats.efficiency_multiplier]

	if fling_type_selector:
		var fling_stats = fling_upgrades[selected_fling_type]
		fling_type_selector.text = "Fling: %.1fx Force, -%.0fs Cooldown" % [fling_stats.force_multiplier, fling_stats.cooldown_reduction]

	if money:
		money.text = "$" + str(player_money)

	update_upgrade_info()

func update_upgrade_info():
	var info_text = "Distance: %.0fm\n" % shop_distance
	info_text += "Money: $" + str(player_money) + "\n\n"

	var car_stats = car_upgrades[selected_car_type]
	info_text += "Car Stats:\n"
	info_text += "Speed: %.1fx\n" % car_stats.max_speed_multiplier
	info_text += "Acceleration: %.1fx\n" % car_stats.acceleration_multiplier
	info_text += "Handling: %.1fx\n\n" % car_stats.handling_multiplier

	var engine_stats = engine_upgrades[selected_engine_type]
	info_text += "Engine Stats:\n"
	info_text += "Torque: %.1fx\n" % engine_stats.torque_multiplier
	info_text += "Efficiency: %.1fx\n\n" % engine_stats.efficiency_multiplier

	var fling_stats = fling_upgrades[selected_fling_type]
	info_text += "Fling Stats:\n"
	info_text += "Force: %.1fx\n" % fling_stats.force_multiplier
	info_text += "Cooldown: -%.0fs\n" % fling_stats.cooldown_reduction
	info_text += "Duration: %.1fx" % fling_stats.duration_multiplier

	if upgrade_description:
		upgrade_description.text = info_text

func get_car_stats():
	return car_upgrades[selected_car_type]

func get_engine_stats():
	return engine_upgrades[selected_engine_type]

func get_fling_stats():
	return fling_upgrades[selected_fling_type]

func add_money(amount: int):
	player_money += amount
	update_ui()

func save_upgrades():
	var save_data = {
		"car_type": selected_car_type,
		"engine_type": selected_engine_type,
		"fling_type": selected_fling_type,
		"money": player_money
	}
	globals.save_upgrade_data(save_data)

func load_upgrades():
	var save_data = globals.load_upgrade_data()
	if save_data:
		selected_car_type = save_data.get("car_type", "basic")
		selected_engine_type = save_data.get("engine_type", "stock")
		selected_fling_type = save_data.get("fling_type", "basic")
		player_money = save_data.get("money", 5000)
		update_ui()
