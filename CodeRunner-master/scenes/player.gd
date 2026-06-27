extends CharacterBody2D

var tile_size = 32

var is_moving = false
var is_jumping = false
var is_falling = false
var is_dead = false
var is_attacking =false
var start_position = Vector2()

@onready var spike_check = $SpikeCheck
@onready var wall_check = $WallCheck
@onready var floor_check = $FloorCheck
@onready var sprite = $Visual/Knight


func _ready():
	start_position = position
	set_state_idle()


# =====================================================
# STATE / ANIMATION
# =====================================================

func play_anim(anim_name):
	if sprite.animation != anim_name:
		sprite.play(anim_name)


func set_state_idle():
	play_anim("idle")
	AudioManager.stop_footsteps()


func set_state_run():
	play_anim("run")
	AudioManager.play_footsteps()


func set_state_jump():
	play_anim("jump")
	AudioManager.stop_footsteps()


func set_state_fall():
	play_anim("fall")
	AudioManager.stop_footsteps()


func set_state_death():
	play_anim("death")
	AudioManager.stop_footsteps()


func stop_action():
	if is_dead:
		return

	is_moving = false
	is_jumping = false
	is_falling = false

	set_state_idle()


# =====================================================
# CORE MOVEMENT
# =====================================================

func move_along_path(path: Array, duration := 0.4):

	if is_moving:
		return false

	if path.is_empty():
		return false

	is_moving = true

	var tween = create_tween()
	var segment_duration = duration / path.size()

	for point in path:
		tween.tween_property(
			self,
			"position",
			point,
			segment_duration
		)

	await tween.finished

	is_moving = false
	return true


func blocked(offset: Vector2):
	wall_check.target_position = offset
	wall_check.force_raycast_update()
	return wall_check.is_colliding()


# =====================================================
# WALK
# =====================================================

func move_right():

	if is_dead or is_moving:
		return false

	sprite.flip_h = false

	if blocked(Vector2(tile_size, 0)):
		return false

	set_state_run()

	var next = position + Vector2(tile_size, 0)

	await move_along_path([next], 0.18)

	return true


func move_left():

	if is_dead or is_moving:
		return false

	sprite.flip_h = true

	if blocked(Vector2(-tile_size, 0)):
		return false

	set_state_run()

	var next = position + Vector2(-tile_size, 0)

	await move_along_path([next], 0.18)

	return true


# =====================================================
# FALL
# =====================================================

func move_down():

	if is_dead or is_moving:
		return false

	floor_check.target_position = Vector2(0, tile_size)
	floor_check.force_raycast_update()

	if floor_check.is_colliding():
		return false

	is_falling = true
	set_state_fall()

	var next = position + Vector2(0, tile_size)

	await move_along_path([next], 0.12)

	is_falling = false

	return true


func should_fall():
	print(global_position.y)
	floor_check.target_position = Vector2(0, tile_size)
	floor_check.force_raycast_update()

	return !floor_check.is_colliding()

# =====================================================
# JUMP
# =====================================================

func jump_right():

	if is_dead or is_moving:
		return false

	sprite.flip_h = false

	var peak = position + Vector2(tile_size, -tile_size)
	var landing = position + Vector2(tile_size * 2, 0)

	if blocked(Vector2(tile_size, -tile_size)):
		return false

	is_jumping = true
	set_state_jump()
	AudioManager.play_sfx("jump")

	await move_along_path(
		[
			peak,
			landing
		],
		0.45
	)

	is_jumping = false

	return true


func jump_left():

	if is_dead or is_moving:
		return false

	sprite.flip_h = true

	var peak = position + Vector2(-tile_size, -tile_size)
	var landing = position + Vector2(-tile_size * 2, 0)

	if blocked(Vector2(-tile_size, -tile_size)):
		return false

	is_jumping = true
	set_state_jump()
	AudioManager.play_sfx("jump")

	await move_along_path(
		[
			peak,
			landing
		],
		0.45
	)

	is_jumping = false

	return true


func jump_up():

	if is_dead or is_moving:
		return false

	var next = position + Vector2(0, -tile_size * 2)

	if blocked(Vector2(0, -tile_size)):
		return false

	is_jumping = true
	set_state_jump()
	AudioManager.play_sfx("jump")

	await move_along_path([next], 0.25)

	is_jumping = false
	return true


# =====================================================
# RESET / DEATH
# =====================================================

func reset_player():

	position = start_position

	is_moving = false
	is_jumping = false
	is_falling = false

	set_state_idle()


func die():

	if is_dead:
		return

	is_dead = true

	is_moving = false
	is_jumping = false
	is_falling = false

	set_state_death()

	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

# =====================================================
# DETECTION
# =====================================================

func wall_on_right():

	wall_check.target_position = Vector2(tile_size, 0)
	wall_check.force_raycast_update()
	return wall_check.is_colliding()
	
func wall_on_left() -> bool:
	wall_check.target_position = Vector2(-tile_size, 0) # Mengecek 	ke arah kiri
	wall_check.force_raycast_update()
	return wall_check.is_colliding()

func spike_ahead():

	if sprite.flip_h:
		spike_check.target_position = Vector2(-tile_size, 0)
	else:
		spike_check.target_position = Vector2(tile_size, 0)

	spike_check.force_raycast_update()

	return spike_check.is_colliding()
func tebas():
	if is_attacking: return
	is_attacking = true
	$Visual/Knight.play("attack")
	$SwordHitbox/CollisionShape2D.disabled = false
	await get_tree().create_timer(0.2).timeout
	$SwordHitbox/CollisionShape2D.disabled = true
	is_attacking = false
var command_queue = []
var is_executing = false

func _process(delta):
	if command_queue.size() > 0 and not is_executing and not is_moving and is_jumping and not is_attacking and not is_falling:
		execute_command(command_queue.pop_front())

func execute_command(cmd: String):
	is_executing = true
	
	match cmd:
		"tebas":
			tebas()
			await get_tree().create_timer(0.3).timeout
		"move_right":
			await move_right()
		"move_left":
			await move_left()
		"jump_right":
			await jump_right()
		"jump_left":
			await jump_left()
		"jump_up":
			await jump_up()
		"spike_ahead":
			print("spike depan:", spike_ahead())
		_:
			print("perintah tak dikenal:", cmd)
	is_executing = false
