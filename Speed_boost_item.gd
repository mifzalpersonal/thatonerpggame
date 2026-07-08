extends Area3D

@export var speed_multiplier: float = 10.0 # Menjadi 1.5x lebih cepat
@export var duration: float = 5.0          # Durasi dalam detik

func _ready():
	body_entered.connect(_on_body_entered)
	
# Fungsi ini berjalan setiap frame
func _process(delta: float):
	# Memutar item pada sumbu Y (vertikal) sebesar 2 radian per detik
	rotate_y(2.0 * delta)

func _on_body_entered(body: Node3D):
	# Karena efek speed biasanya mengatur pergerakan, fungsinya ditaruh di script utama Player (body)
	if body.has_method("apply_speed_boost"):
		body.apply_speed_boost(speed_multiplier, duration)
		queue_free()
