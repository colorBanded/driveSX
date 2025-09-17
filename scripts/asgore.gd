extends VehicleBody3D

@export var base_max_torque = 150.0
@export var base_brake_force = 50.0
@export var base_fling_force = 500.0
@export var base_fling_upward_force = 200.0
@export var base_fling_cooldown_duration = 45.0
@export var base_fling_active_duration = 2.0
@onready var shop_label: Label = $"../shop_label"

var shop_unlock_distance: float = 500.0

var max_torque = 150.0
var brake_force = 50.0
var fling_force = 500.0
var fling_upward_force = 200.0
var fling_cooldown_duration = 45.0
var fling_active_duration = 2.0

@onready var progress_bar: ProgressBar = $"../ProgressBar"

var current_engine_force = 0.0
var current_steering = 0.0

var current_speed_kmh = 0.0
var current_speed_mph = 0.0

var fling_cooldown_timer = 0.0
var is_fling_on_cooldown = false

var fling_active = false
var fling_active_timer = 0.0

var display_gear = "D"
var rpm = 800.0

var flip_recovery_active = false
var flip_recovery_timer = 0.0
var flip_recovery_duration = 2.0

var car_multipliers = {}
var engine_multipliers = {}
var fling_multipliers = {}

var origin_position: Vector3
var distance_from_origin: float = 0.0

func _ready():
	origin_position = global_position
	
	apply_upgrades()
	
	if globals.should_restore_position():
		global_position = globals.get_return_position()
		global_rotation = globals.get_return_rotation()
		globals.distance = globals.return_distance
		
		globals.return_position = Vector3.ZERO
		globals.return_rotation = Vector3.ZERO
		globals.return_distance = 0.0
		
		origin_position = global_position
	
	shop_unlock_distance = 500.0
	
	if progress_bar:
		progress_bar.min_value = 0.0
		progress_bar.max_value = fling_cooldown_duration
		progress_bar.value = fling_cooldown_duration
		progress_bar.show_percentage = true

func apply_upgrades():
	car_multipliers = globals.get_car_stats()
	engine_multipliers = globals.get_engine_stats()
	fling_multipliers = globals.get_fling_stats()
	
	var car_handling = car_multipliers.get("handling_multiplier", 1.0)
	var car_acceleration = car_multipliers.get("acceleration_multiplier", 1.0)
	
	var engine_torque = engine_multipliers.get("torque_multiplier", 1.0)
	
	var fling_force_mult = fling_multipliers.get("force_multiplier", 1.0)
	var cooldown_reduction = fling_multipliers.get("cooldown_reduction", 0.0)
	var duration_mult = fling_multipliers.get("duration_multiplier", 1.0)
	
	max_torque = base_max_torque * engine_torque * car_acceleration
	brake_force = base_brake_force * car_handling
	fling_force = base_fling_force * fling_force_mult
	fling_upward_force = base_fling_upward_force * fling_force_mult
	fling_cooldown_duration = max(5.0, base_fling_cooldown_duration - cooldown_reduction)
	fling_active_duration = base_fling_active_duration * duration_mult
	
	if progress_bar:
		progress_bar.max_value = fling_cooldown_duration

func _physics_process(delta):
	distance_from_origin = (global_position - origin_position).length()
	globals.update_distance(globals.distance + distance_from_origin)
	
	update_shop_distance_display()
	check_shop_unlock()
	
	update_fling_cooldown(delta)
	update_fling_active(delta)
	
	if (Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_F)) and not is_fling_on_cooldown and not fling_active:
		fling_vehicle()
	
	handle_flip_recovery(delta)
	
	var target_engine = 0.0
	var target_steering = 0.0
	
	if Input.is_action_pressed("pm_moveforward"):
		target_engine = 1.0
		display_gear = "D"
	elif Input.is_action_pressed("pm_movebackward"):
		target_engine = -1.0
		display_gear = "R"
	else:
		target_engine = 0.0
	
	var steering_responsiveness = car_multipliers.get("handling_multiplier", 1.0)
	if Input.is_action_pressed("pm_moveleft"):
		target_steering = 0.4 * steering_responsiveness
	elif Input.is_action_pressed("pm_moveright"):
		target_steering = -0.4 * steering_responsiveness
	else:
		target_steering = 0.0
	
	var acceleration_response = car_multipliers.get("acceleration_multiplier", 1.0)
	current_engine_force = lerp(current_engine_force, target_engine, delta * 5.0 * acceleration_response)
	current_steering = lerp(current_steering, target_steering, delta * 8.0 * steering_responsiveness)
	
	var engine_power = current_engine_force * max_torque
	
	$WheelFL.steering = current_steering
	$WheelFR.steering = current_steering
	
	update_speed()
	update_rpm()
	
	$WheelBL.engine_force = engine_power
	$WheelBR.engine_force = engine_power
	
	if abs(target_engine) < 0.1:
		$WheelBL.brake = brake_force * 0.2
		$WheelBR.brake = brake_force * 0.2
		$WheelFL.brake = brake_force * 0.2
		$WheelFR.brake = brake_force * 0.2
	else:
		$WheelBL.brake = 0.0
		$WheelBR.brake = 0.0
		$WheelFL.brake = 0.0
		$WheelFR.brake = 0.0

func update_shop_distance_display():
	if shop_label:
		var distance_remaining = max(0.0, shop_unlock_distance - distance_from_origin)
		
		if distance_remaining <= 0:
			shop_label.text = "Shop: Available (Press B)"
			shop_label.modulate = Color.CYAN
		else:
			if distance_remaining >= 1000.0:
				shop_label.text = "Shop: %.1f km" % (distance_remaining / 1000.0)
			else:
				shop_label.text = "Shop: %.0f m" % distance_remaining
			
			var progress_ratio = distance_from_origin / shop_unlock_distance
			shop_label.modulate = Color.RED.lerp(Color.GREEN, progress_ratio)

func check_shop_unlock():
	if distance_from_origin >= shop_unlock_distance:
		if Input.is_action_just_pressed("ui_cancel") or Input.is_key_pressed(KEY_B):
			visit_shop()

func visit_shop():
	var progression = globals.get_shop_progression()
	var current_total_distance = globals.distance + distance_from_origin
	var new_shop_count = progression.shop_count + 1
	
	globals.save_shop_progression(
		current_total_distance,
		current_total_distance + 500.0,
		new_shop_count
	)
	
	globals.set_return_position(global_position)
	globals.set_return_rotation(global_rotation)
	
	get_tree().change_scene_to_file("res://scenes/shop.tscn")

func update_fling_cooldown(delta):
	if is_fling_on_cooldown:
		fling_cooldown_timer -= delta
		
		if progress_bar:
			progress_bar.value = fling_cooldown_timer
			
			if fling_cooldown_timer <= 0.0:
				progress_bar.modulate = Color.GREEN
			else:
				var progress_ratio = fling_cooldown_timer / fling_cooldown_duration
				progress_bar.modulate = Color.RED.lerp(Color.YELLOW, 1.0 - progress_ratio)
		
		if fling_cooldown_timer <= 0.0:
			is_fling_on_cooldown = false
			fling_cooldown_timer = 0.0
	else:
		if progress_bar:
			progress_bar.value = fling_cooldown_duration
			progress_bar.modulate = Color.GREEN

func update_fling_active(delta):
	if fling_active:
		fling_active_timer -= delta
		
		if fling_active_timer <= 0.0:
			fling_active = false
			fling_active_timer = 0.0

func fling_vehicle():
	var forward_direction = global_transform.basis.z
	var upward_direction = Vector3.UP
	
	var fling_impulse = (forward_direction * fling_force) + (upward_direction * fling_upward_force)
	
	apply_central_impulse(fling_impulse)
	
	start_fling_active()
	start_fling_cooldown()

func start_fling_active():
	fling_active = true
	fling_active_timer = fling_active_duration

func start_fling_cooldown():
	is_fling_on_cooldown = true
	fling_cooldown_timer = fling_cooldown_duration
	
	if progress_bar:
		progress_bar.value = fling_cooldown_timer
		progress_bar.modulate = Color.RED

func handle_flip_recovery(delta):
	var up_dot = global_transform.basis.y.dot(Vector3.UP)
	var is_upside_down = up_dot < -0.1
	
	if is_upside_down and not flip_recovery_active:
		flip_recovery_timer = 0.8
		flip_recovery_active = true
	elif not is_upside_down and flip_recovery_active:
		flip_recovery_active = false
		flip_recovery_timer = 0.0
	
	if flip_recovery_active:
		flip_recovery_timer -= delta
		
		if flip_recovery_timer <= 0.0:
			var recovery_force = Vector3.UP * 100.0
			apply_central_force(recovery_force)
			
			var target_up = Vector3.UP
			var current_up = global_transform.basis.y
			var torque_axis = current_up.cross(target_up)
			
			if torque_axis.length() > 0.01:
				var torque_strength = 50.0
				apply_torque_impulse(torque_axis.normalized() * torque_strength * delta * 60.0)
			
			flip_recovery_timer = 0.1

func update_speed():
	var velocity_ms = linear_velocity.length()
	current_speed_kmh = velocity_ms * 3.6
	current_speed_mph = velocity_ms * 2.237

func update_rpm():
	var base_rpm = 800.0
	var throttle_input = abs(current_engine_force)
	
	var efficiency = engine_multipliers.get("efficiency_multiplier", 1.0)
	
	if current_speed_kmh > 0.5:
		rpm = base_rpm + (current_speed_kmh * 25.0 * efficiency) + (throttle_input * 2000.0 * efficiency)
		rpm = clamp(rpm, base_rpm, 6000.0 * efficiency)
	else:
		rpm = base_rpm + (throttle_input * 1000.0)

func get_speed_kmh() -> float:
	return current_speed_kmh

func get_speed_mph() -> float:
	return current_speed_mph

func get_distance_from_origin() -> float:
	return distance_from_origin

func get_rpm() -> float:
	return rpm

func get_gear_name() -> String:
	return display_gear

func is_fling_available() -> bool:
	return not is_fling_on_cooldown and not fling_active

func is_fling_currently_active() -> bool:
	return fling_active

func get_fling_active_time_remaining() -> float:
	return fling_active_timer if fling_active else 0.0

func get_fling_cooldown_remaining() -> float:
	return fling_cooldown_timer if is_fling_on_cooldown else 0.0

func get_fling_cooldown_progress() -> float:
	if not is_fling_on_cooldown:
		return 1.0
	return 1.0 - (fling_cooldown_timer / fling_cooldown_duration)

func get_distance_to_shop_display() -> String:
	var distance_remaining = max(0.0, shop_unlock_distance - distance_from_origin)
	
	if distance_remaining <= 0:
		return "Shop: Available (Press B)"
	elif distance_remaining >= 1000.0:
		return "Shop: %.1f km" % (distance_remaining / 1000.0)
	else:
		return "Shop: %.0f m" % distance_remaining

func is_shop_available() -> bool:
	return distance_from_origin >= shop_unlock_distance

func refresh_upgrades():
	apply_upgrades()

func get_current_upgrades() -> Dictionary:
	return {
		"car": car_multipliers,
		"engine": engine_multipliers,
		"fling": fling_multipliers
	}

func reset_shop_system():
	globals.reset_shop_progression()
	shop_unlock_distance = 500.0

func find_camera_in_scene() -> Node3D:
	var cameras = get_tree().get_nodes_in_group("camera")
	if cameras.size() > 0:
		return cameras[0]
	return find_camera3d_recursive(get_tree().root)

func find_camera3d_recursive(node: Node) -> Node3D:
	if node is Camera3D:
		return node as Node3D
	for child in node.get_children():
		var result = find_camera3d_recursive(child)
		if result:
			return result
	return null
