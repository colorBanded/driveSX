extends Node
class_name Globals

var distance = 0.0
var best_distance = 0.0
var current_run_money = 0

var return_position = Vector3.ZERO
var return_rotation = Vector3.ZERO
var return_distance = 0.0

var upgrade_data = {
	"car_type": "basic",
	"engine_type": "stock",
	"fling_type": "basic",
	"money": 5000
}

var shop_instance = null

func _ready():
	load_upgrade_data()

func set_return_position(pos: Vector3):
	return_position = pos

func get_return_position() -> Vector3:
	return return_position

func set_return_rotation(rot: Vector3):
	return_rotation = rot

func get_return_rotation() -> Vector3:
	return return_rotation

func set_return_data(pos: Vector3, rot: Vector3, dist: float):
	return_position = pos
	return_rotation = rot
	return_distance = dist

func should_restore_position() -> bool:
	return return_position != Vector3.ZERO

func update_distance(new_distance: float):
	distance = new_distance
	if distance > best_distance:
		best_distance = distance
	
	var money_earned = int(distance / 10.0)
	current_run_money = money_earned

func finish_run():
	if current_run_money > 0:
		upgrade_data.money += current_run_money
		print("Earned $", current_run_money, " from distance!")
		
		var shopasd = get_shop_instance()
		if shopasd:
			shopasd.player_money = upgrade_data.money
			shopasd.update_ui()
		
		save_upgrade_data()
	
	reset_current_run()

func reset_current_run():
	distance = 0.0
	current_run_money = 0
	if upgrade_data.has("shop_progression"):
		upgrade_data.shop_progression.shops_visited_this_run = false
		save_upgrade_data()

func get_shop_instance():
	if not shop_instance:
		shop_instance = get_tree().get_first_node_in_group("shop")
	return shop_instance

func get_car_stats():
	var shop = get_shop_instance()
	if shop:
		return shop.get_car_stats()
	else:
		return {
			"max_speed_multiplier": 1.0,
			"acceleration_multiplier": 1.0,
			"handling_multiplier": 1.0
		}

func get_engine_stats():
	var shop = get_shop_instance()
	if shop:
		return shop.get_engine_stats()
	else:
		return {
			"torque_multiplier": 1.0,
			"efficiency_multiplier": 1.0
		}

func get_fling_stats():
	var shop = get_shop_instance()
	if shop:
		return shop.get_fling_stats()
	else:
		return {
			"force_multiplier": 1.0,
			"cooldown_reduction": 0.0,
			"duration_multiplier": 1.0
		}

func get_shop_progression() -> Dictionary:
	if not upgrade_data.has("shop_progression"):
		upgrade_data.shop_progression = {
			"last_shop_distance": 0.0,
			"next_shop_distance": 500.0,
			"shop_count": 0,
			"shops_visited_this_run": false
		}
		save_upgrade_data()
	return upgrade_data.shop_progression

func save_shop_progression(last_distance: float, next_distance: float, count: int):
	upgrade_data.shop_progression = {
		"last_shop_distance": last_distance,
		"next_shop_distance": next_distance,
		"shop_count": count,
		"shops_visited_this_run": true
	}
	save_upgrade_data()
	print("Shop progression saved: Shop #", count, " completed. Next shop at: ", next_distance, "m")

func reset_shop_progression():
	upgrade_data.shop_progression = {
		"last_shop_distance": 0.0,
		"next_shop_distance": 500.0,
		"shop_count": 0,
		"shops_visited_this_run": false
	}
	save_upgrade_data()
	print("Shop progression reset to beginning")

func calculate_shop_distance_for_count(shop_count: int) -> float:
	if shop_count == 0:
		return 500.0
	elif shop_count == 1:
		return 1000.0
	elif shop_count == 2:
		return 2100.0
	else:
		var base_distance = 2100.0
		var additional_shops = shop_count - 2
		return base_distance + (additional_shops * 1500.0) + pow(additional_shops, 1.5) * 300.0

func print_shop_progression():
	print("=== SHOP PROGRESSION ===")
	for i in range(10):
		var distance = calculate_shop_distance_for_count(i)
		print("Shop #", i + 1, ": ", distance, "m")
	print("========================")

func save_upgrade_data(data = null):
	if data != null:
		upgrade_data = data
	
	var file = FileAccess.open("user://upgrades.save", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(upgrade_data))
		file.close()
		print("Upgrades saved successfully")
	else:
		print("Failed to open save file for writing")

func load_upgrade_data():
	var file = FileAccess.open("user://upgrades.save", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			upgrade_data = json.data
			print("Upgrades loaded successfully")
			return upgrade_data
		else:
			print("Failed to parse save file")
	else:
		print("No save file found, using defaults")
	
	return upgrade_data

func add_money(amount: int):
	upgrade_data.money += amount
	var shop = get_shop_instance()
	if shop:
		shop.player_money = upgrade_data.money
		shop.update_ui()
	save_upgrade_data()

func spend_money(amount: int) -> bool:
	if upgrade_data.money >= amount:
		upgrade_data.money -= amount
		save_upgrade_data()
		return true
	return false

func get_money() -> int:
	return upgrade_data.money
