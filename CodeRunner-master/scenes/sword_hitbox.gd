extends Area2D


func on_sword_hit(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		body.kena_tebas
