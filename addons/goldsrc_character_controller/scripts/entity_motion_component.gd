class_name EntityMotionComponent extends Node

@export_group("Components")
@export var Config : EntityConfig
@export var Body : EntityBodyComponent

var movement_vector : Vector3

func calculate_movement_vector(input_direction: Vector3, rotation_radians: float) -> void:

	var speeds := Vector2(Config.SIDE_SPEED, Config.FORWARD_SPEED)

	for i in range(2):
		if speeds[i] > Config.MAX_SPEED:
			speeds[i] *= Config.MAX_SPEED / speeds[i]

	var move_dir = Vector3(input_direction.x * speeds.x, 0, input_direction.z * speeds.y).rotated(Vector3.UP, rotation_radians)

	if Body.ducked:
		move_dir *= Config.DUCKING_SPEED_MULTIPLIER

	if (move_dir.length() > Config.MAX_SPEED):
		move_dir *= Config.MAX_SPEED / move_dir.length()

	movement_vector = move_dir

func accelerate() -> void:
	if !Body: return

	var addspeed : float
	var accelspeed : float
	var currentspeed : float
	var delta : float = get_physics_process_delta_time()
	var wishdir : Vector3 = movement_vector.normalized()
	var wishspeed : float = movement_vector.length()

	currentspeed = Body.velocity.dot(wishdir)

	addspeed = wishspeed - currentspeed

	if addspeed <= 0:
		return;

	accelspeed = Config.ACCELERATION * wishspeed * delta

	if accelspeed > addspeed:
		accelspeed = addspeed

	Body.velocity += accelspeed * wishdir

func airaccelerate() -> void:
	if !Body: return

	var addspeed : float
	var accelspeed : float
	var currentspeed : float
	var delta : float = get_physics_process_delta_time()
	var wishdir : Vector3 = movement_vector.normalized()
	var wishspeed : float = movement_vector.length()
	var wishspd : float = wishspeed

	if (wishspd > Config.MAX_AIR_SPEED):
		wishspd = Config.MAX_AIR_SPEED

	currentspeed = Body.velocity.dot(wishdir)

	addspeed = wishspd - currentspeed

	if addspeed <= 0:
		return;

	accelspeed = Config.AIR_ACCELERATION * wishspeed * delta

	if accelspeed > addspeed:
		accelspeed = addspeed

	Body.velocity += accelspeed * wishdir

func friction(strength: float) -> void:
	if !Body: return

	var speed : float = Body.velocity.length()
	var delta : float = get_physics_process_delta_time()

	var control =  Config.STOP_SPEED if (speed < Config.STOP_SPEED) else speed

	var drop = control * (Config.FRICTION * strength) * delta

	var newspeed = speed - drop

	if newspeed < 0:
		newspeed = 0

	if speed > 0:
		newspeed /= speed

	Body.velocity.x *= newspeed
	Body.velocity.z *= newspeed

func jump() -> void:
	var delta : float = get_physics_process_delta_time()

	Body.velocity.y = sqrt(2 * Config.GRAVITY * Config.JUMP_HEIGHT)

	Body.velocity.y -= (Config.GRAVITY * delta * 0.5 )

	match Config.BUNNYHOP_CAP_MODE:
		Config.BunnyhopCapMode.NONE:
			pass
		Config.BunnyhopCapMode.THRESHOLD:
			bunnyhop_capmode_threshold()
		Config.BunnyhopCapMode.DROP:
			bunnyhop_capmode_drop()

func bunnyhop_capmode_threshold() -> void:
	var spd : float
	var fraction : float
	var maxscaledspeed : float

	maxscaledspeed = Config.SPEED_THRESHOLD_FACTOR * Config.MAX_SPEED

	if (maxscaledspeed <= 0): 
		return

	spd = Vector3(Body.velocity.x, 0.0, Body.velocity.z).length()

	if (spd <= maxscaledspeed): return

	fraction = (maxscaledspeed / spd)

	Body.velocity.x *= fraction
	Body.velocity.z *= fraction

func bunnyhop_capmode_drop() -> void:
	var spd : float
	var fraction : float
	var maxscaledspeed : float
	var dropspeed : float

	maxscaledspeed = Config.SPEED_THRESHOLD_FACTOR * Config.MAX_SPEED
	dropspeed = Config.SPEED_DROP_FACTOR * Config.MAX_SPEED

	if (maxscaledspeed <= 0): 
		return

	spd = Vector3(Body.velocity.x, 0.0, Body.velocity.z).length()

	if (spd <= maxscaledspeed): return

	fraction = (dropspeed / spd)

	Body.velocity.x *= fraction
	Body.velocity.z *= fraction
