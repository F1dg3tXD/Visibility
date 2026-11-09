extends CharacterBody3D

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var head: Node3D = $Head
@onready var pickup: RayCast3D = $Head/RayCast3D
@onready var crosshair: Control = $Crosshair
@onready var no_check: Control = $no_check
@onready var hand: Node3D = $Head/Hand

# The time limit for the game is from here
@onready var shit_meter: Control = $shitMeter
@onready var ending_screen: Control = $EndingScreen
@onready var footsteps: AudioStreamPlayer3D = $footsteps
@onready var crt: ColorRect = $CRT/ColorRect
const CRT_OVERLAY = preload("res://shaders/CRTOverlay.tres")



@export_flags_3d_physics var interaction_collision_layers: int = 2
var _current_interactable: Node = null

var _flashing_no_check: bool = false
var _flash_timer: float = 0.0
var _bob_time: float = 0.0
var _footstep_timer: float = 0.0
var _light_on: bool = true

var held_object: RigidBody3D = null

@export var hold_distance: float = 2.0
@export var hold_strength: float = 10.0

var current_rwc: float = 0.0
var current_idw: float = 1.0

# --- Movement constants ---
@export var SPEED := 5.0
@export var RUN_SPEED := 8.0
@export var JUMP_VELOCITY := 4.5

# --- Capsule heights ---
@export var STAND_HEIGHT := 1.8
@export var CROUCH_HEIGHT := 1.0
@export var CROUCH_SPEED := 3.0

# --- Mouse look ---
@export var mouse_sensitivity: float = 0.0025
@export var controller_sensitivity: float = 5.0 # tweak for stick speed
var yaw: float = 0.0
var pitch: float = 0.0

# --- Melting ---
const MELT_TIME := 1.0

# --- State ---
var is_crouching: bool = false
var target_height: float = STAND_HEIGHT
var ice_spawned: bool = false

func _get_interactable_from_collider(collider: Object) -> Node:
	var node := collider as Node
	while node != null:
		if node.is_in_group("interactable") and node.has_method("interact"):
			return node
		node = node.get_parent()
	return null


func _ready() -> void:
	add_to_group("player")
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	crosshair.visible = false
	no_check.visible = false
	pickup.collide_with_areas = true
	pickup.collision_mask = 5 | interaction_collision_layers
	if shit_meter:
		shit_meter.warning_reached.connect(_on_shit_meter_warning)
		shit_meter.time_ended.connect(_on_shit_meter_ended)

func _on_shit_meter_warning(_percent: float) -> void:
	no_check.visible = true
	_flashing_no_check = true
	_flash_timer = 0.0

func _on_shit_meter_ended() -> void:
	_flashing_no_check = false
	no_check.visible = false

func lock_input() -> void:
	set_process_input(false)
	if pickup:
		pickup.enabled = false

func show_ending(ending_type: int) -> void:
	if ending_screen == null:
		return
	match ending_type:
		0:
			if ending_screen.has_method("show_win"):
				ending_screen.show_win()
		1:
			if ending_screen.has_method("show_loose"):
				ending_screen.show_loose()
		2:
			if ending_screen.has_method("show_why"):
				ending_screen.show_why()
		3:
			if ending_screen.has_method("show_death"):
				ending_screen.show_death()


func _input(event: InputEvent) -> void:
	# Mouse look.
	if event is InputEventMouseMotion:
		yaw += event.relative.x * mouse_sensitivity
		pitch += event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -1.5, 1.5)
		rotation.y = -yaw
		head.rotation.x = pitch
	# Interaction / pickup.
	if event.is_action_pressed("interact"):
		if event.is_echo():
			return
		# Refresh the raycast before deciding what we're looking at.
		_update_interactable_target()
		# INTERACTION TAKES PRIORITY.
		if is_instance_valid(_current_interactable):
			if _current_interactable.has_method("register_input_event"):
				_current_interactable.call("register_input_event", event)
			_current_interactable.call("interact")
			get_viewport().set_input_as_handled()
			return
		# No interaction volume targeted.
		# Preserve existing object pickup/release behavior.
		if is_instance_valid(held_object):
			held_object = null
			crosshair.visible = false
		else:
			held_object = null
			if pickup.is_colliding():
				var collider = pickup.get_collider()
				if collider is RigidBody3D:
					held_object = collider
					crosshair.visible = true
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_update_interactable_target()
	# Toggle light
	if Input.is_action_just_pressed("toggle_light"):
		_light_on = not _light_on
		# rotate hand down when off
		if _light_on:
			hand.rotation.x = 0.0
		else:
			hand.rotation.x = deg_to_rad(60.0)
	# Head/hand bob
	var speed2d := Vector2(velocity.x, velocity.z).length()
	var sprinting := Input.is_action_pressed("sprint") and speed2d > 0.1
	var bob_speed := 12.0 if sprinting else 8.0
	_bob_time += delta * bob_speed
	# Footsteps
	var sprinting2 := Input.is_action_pressed("sprint") and speed2d > 0.1
	var interval := 0.5 if sprinting2 else 1.0
	if speed2d > 0.1:
		_footstep_timer += delta
		if _footstep_timer >= interval:
			_footstep_timer = 0.0
			if footsteps:
				footsteps.play()
	else:
		_footstep_timer = 0.0

	# CRT overlay param update using crt ColorRect.
	if crt and crt.material is ShaderMaterial:
		var crt_mat := crt.material as ShaderMaterial
		if shit_meter and shit_meter.get("_elapsed") != null:
			var ratio := clampf(shit_meter._elapsed / shit_meter.TimeLimit, 0.0, 1.0)
			var curve_val := 0.0
			var mask_val := 1.0
			if ratio > 0.5:
				var t := (ratio - 0.5) / 0.5
				curve_val = lerpf(0.0, 0.5, t)
				mask_val = lerpf(1.0, 0.5, t)
			crt_mat.set_shader_parameter("curve", curve_val)
			crt_mat.set_shader_parameter("mask_brightness", mask_val)
	var bob_amount := clampf(speed2d / 5.0, 0.0, 1.0)
	var capsule := collision_shape_3d.shape as CapsuleShape3D
	var base_head_y := target_height * 0.5 + capsule.radius
	head.position.y = base_head_y + sin(_bob_time) * 0.05 * bob_amount
	hand.position.y = sin(_bob_time + 0.5) * 0.03 * bob_amount
	if _flashing_no_check:
		_flash_timer += delta
		if _flash_timer >= 0.25:
			_flash_timer = 0.0
			no_check.visible = not no_check.visible
	# --- CONTROLLER LOOK ---
	var look_input := Vector2.ZERO
	look_input.x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	look_input.y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")

	if look_input.length() > 0.01:
		yaw -= look_input.x * controller_sensitivity * delta
		pitch += look_input.y * controller_sensitivity * delta
		pitch = clamp(pitch, -1.2, 1.2)

		rotation.y = yaw
		head.rotation.x = pitch
	
	# If holding something, keep moving it to the hold position
	if held_object:
		var target_pos = pickup.global_transform.origin + pickup.global_transform.basis.z * -hold_distance
		var dir = target_pos - held_object.global_transform.origin
		held_object.linear_velocity = dir * hold_strength
		crosshair.visible = true
		#gun_animation_player.play("Grab")
		
	

func _physics_process(delta: float) -> void:
	# --- Gravity ---
	if not is_on_floor():
		velocity += get_gravity() * delta

	# --- Jump ---
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY

	# --- Crouch (hold style) ---
	if Input.is_action_pressed("crouch"):
		if not is_crouching:
			start_crouch()
	else:
		if is_crouching:
			stop_crouch()

	# --- Smooth capsule resize ---
	var capsule := collision_shape_3d.shape as CapsuleShape3D
	capsule.height = lerp(capsule.height, target_height, delta * CROUCH_SPEED)

	# Adjust head position
	var head_target_y := target_height * 0.5 + capsule.radius
	head.position.y = lerp(head.position.y, head_target_y, delta * CROUCH_SPEED)

	# --- Smooth movement input with stick magnitude ---
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var input_strength := input_dir.length()
	var target_velocity := Vector3.ZERO

	if input_strength > 0.01:
		var direction := (transform.basis * Vector3(-input_dir.x, 0, -input_dir.y)).normalized()
		var current_speed := SPEED
		if not is_crouching and Input.is_action_pressed("sprint"):
			current_speed = RUN_SPEED
		target_velocity = direction * current_speed * input_strength

	# Smoothly lerp velocity toward target
	var smooth_speed := 10.0 # tweak for responsiveness
	velocity.x = lerp(velocity.x, target_velocity.x, delta * smooth_speed)
	velocity.z = lerp(velocity.z, target_velocity.z, delta * smooth_speed)

	move_and_slide()


func start_crouch() -> void:
	is_crouching = true
	target_height = CROUCH_HEIGHT

func stop_crouch() -> void:
	is_crouching = false
	target_height = STAND_HEIGHT


	# --- Smooth blend between RWC states ---
	var speed2d := Vector2(velocity.x, velocity.z).length()
	var _target_rwc: float = 0.0
	var _target_idw: float = 1.0

	if is_crouching:
		_target_rwc = -1.0
		_target_idw = 1.0
	elif speed2d < SPEED * 0.5:
		_target_rwc = 0.0
		_target_idw = 1.0
	else:
		_target_rwc = 1.0
		_target_idw = 0.0

	# Smoothly lerp stored values
	var _blend_speed := 5.0
	
# Update which interaction volume the player is currently targeting.
func _update_interactable_target() -> void:
	#print("pickup")
	if not is_instance_valid(pickup):
		return
	pickup.force_raycast_update()
	var next_interactable: Node = null
	if pickup.is_colliding():
		next_interactable = _get_interactable_from_collider(
			pickup.get_collider()
		)

	# No change in target.
	if next_interactable == _current_interactable:
		if next_interactable == null:
			#print("_current_interactable")
			return
		if is_instance_valid(_current_interactable):
			#print("_current_interactable2")
			return

	# Hide the previous interaction prompt.
	if is_instance_valid(_current_interactable):
		if _current_interactable.has_method("set_hovered"):
			_current_interactable.call("set_hovered", false)
			print(_current_interactable)
	_current_interactable = next_interactable
	print(_current_interactable)
	# Show the new interaction prompt.
	if is_instance_valid(_current_interactable):
		if _current_interactable.has_method("set_hovered"):
			_current_interactable.call("set_hovered", true)
			print(_current_interactable)

func _exit_tree() -> void:
	if is_instance_valid(_current_interactable):
		if _current_interactable.has_method("set_hovered"):
			_current_interactable.call("set_hovered", false)
			print(_current_interactable)


func _on_shit_meter_warning_reached(percent: float) -> void:
	pass # Replace with function body.
