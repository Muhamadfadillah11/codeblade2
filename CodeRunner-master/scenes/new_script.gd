extends Area2D

func _ready():
	# Kode ajaib: menyambungkan sinyal otomatis saat game jalan, anti-eror pop-up!
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Cek apakah yang menabrak duri adalah Player dan punya fungsi die
	if body.has_method("die"):
		body.die()
