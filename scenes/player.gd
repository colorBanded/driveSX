extends RigidBody3D

@export var engine_power = 400.0  # Reduced power
@export var steering_power = 1.5   # Reduced steering

func _ready():
	sleeping = false
	mass = 2000.0  # Heavier
	angular_damp = 8.0  # Higher damping
	linear_damp = 3.0

func _physics_process(delta):
	var engine_input = 0.0
	if Input.is_action_pressed("pm_moveforward"):
		engine_input = 1.0
	elif Input.is_action_pressed("pm_moveback"):
		engine_input = -1.0
	
	var steering_input = 0.0
	if Input.is_action_pressed("pm_moveleft"):
		steering_input = -1.0
	elif Input.is_action_pressed("pm_moveright"):
		steering_input = 1.0
	
	# Smooth force application
	if engine_input != 0:
		var forward_force = -transform.basis.z * engine_input * engine_power
		apply_central_force(forward_force)
	
	# Only steer when moving
	if linear_velocity.length() > 0.5:
		var torque = Vector3.UP * steering_input * steering_power * min(linear_velocity.length(), 10.0)
		apply_torque(torque)
	
	# Stabilize vertical bouncing
	if linear_velocity.y > 5.0:  # If moving up too fast
		linear_velocity.y *= 0.8  # Dampen it
