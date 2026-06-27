extends CharacterBody2D
class_name Enemy

@export var speed = -50
var hp = 2
var is_dead = false

@onready var anim =$visual/jamur

func _ready():
	anim.play("idle")

func _physics_process(delta):
	if is_dead:
		return
		
	velocity.x = speed
	move_and_slide()
	
	if velocity.x != 0:
		anim.flip_h = velocity.x > 0
	
	if velocity.x != 0:
		if anim.animation !="run":
			anim.play("run")
	else:
		if anim.animation !="idle":
			anim.play("idle")
	
func take_damage(amount: int):
	if is_dead:
		return

	hp -= amount
	anim.play("take_hit")
	await anim.animation_finished
	
	if hp <= 0:
		die()
	else:
		anim.play("run")
	
func die():
	is_dead = true
	speed = 0
	anim.play("death")
	await anim.animation_finished
	queue_free()
	
