# Node3D script (your main scene script)
extends Node3D

@onready var vehicle_body_3d: VehicleBody3D = $VehicleBody3D
@onready var speed: Label = $HBoxContainer/speed
@onready var distance: Label = $HBoxContainer/distance
@onready var gear_label: Label = $HBoxContainer2/gear_label
@onready var rpm_label: Label = $HBoxContainer2/rpm_label

# Gear change limiting variables
var last_gear_change_time: float = 0.0
const GEAR_CHANGE_COOLDOWN: float = 0.2  # Minimum time between gear changes (in seconds)
var pending_gear_change: int = -1  # -1 means no pending change

func _ready():
	# Start updating the UI
	pass

func _process(delta):
	update_ui()
	handle_pending_gear_changes(delta)

# func _input(event):
	# Add your actual input handling here when ready
	# Example: if event.is_action_pressed("your_gear_up_action"):
	#     request_gear_change(1)

func request_gear_change(direction: int):
	"""
	Request a gear change with rate limiting
	direction: 1 for up, -1 for down
	"""
	var current_time = Time.get_time_dict_from_system()
	var time_since_last_change = Time.get_ticks_msec() / 1000.0 - last_gear_change_time
	
	if time_since_last_change >= GEAR_CHANGE_COOLDOWN:
		# Execute gear change immediately
		execute_gear_change(direction)
	else:
		# Store the most recent gear change request
		pending_gear_change = direction

func execute_gear_change(direction: int):
	"""Execute the actual gear change"""
	if vehicle_body_3d:
		if direction == 1:
			vehicle_body_3d.shift_up()
		elif direction == -1:
			vehicle_body_3d.shift_down()
		
		last_gear_change_time = Time.get_ticks_msec() / 1000.0
		pending_gear_change = -1  # Clear any pending change

func handle_pending_gear_changes(delta: float):
	"""Handle any pending gear changes after cooldown period"""
	if pending_gear_change != -1:
		var time_since_last_change = Time.get_ticks_msec() / 1000.0 - last_gear_change_time
		
		if time_since_last_change >= GEAR_CHANGE_COOLDOWN:
			execute_gear_change(pending_gear_change)

func update_ui():
	if vehicle_body_3d and speed and distance:
		# Update speed label (using km/h, but you can change to mph)
		var speed_kmh = vehicle_body_3d.get_speed_kmh()
		speed.text = "Speed: %.1f km/h" % speed_kmh
		
		# Update distance label
		var dist = vehicle_body_3d.get_distance_from_origin()
		
		# Display in meters if less than 1000m, otherwise in kilometers
		if dist < 1000.0:
			distance.text = "Distance: %.1f m" % dist
		else:
			distance.text = "Distance: %.2f km" % (dist / 1000.0)
		
		# Update gear display
		if gear_label:
			var gear_name = vehicle_body_3d.get_gear_name()
			gear_label.text = "Gear: %s" % gear_name
		
		# Update RPM display
		if rpm_label:
			var rpm = vehicle_body_3d.get_rpm()
			rpm_label.text = "RPM: %.0f" % rpm
