extends Area3D

@export var heal_amount: float = 1

func _ready():
	# Hubungkan signal ketika ada body (Player) yang masuk ke area item ini
	body_entered.connect(_on_body_entered)

# Fungsi ini berjalan setiap frame
func _process(delta: float):
	# Memutar item pada sumbu Y (vertikal) sebesar 2 radian per detik
	rotate_y(2.0 * delta)

func _on_body_entered(body: Node3D):
	print("Sesuatu menyentuh item heal: ", body.name) # Ini untuk tes di output
	
	# Cari node darah di player
	var script_darah = body.get_node_or_null("darahEntity") # GANTI "darah" sesuai nama node di Player-mu
	
	if script_darah:
		if script_darah.has_method("heal"):
			script_darah.heal(heal_amount)
			queue_free()
		else:
			print("Error: Node darah ketemu, tapi gak punya fungsi 'heal'!")
	else:
		print("Error: Gak nemu node darah di dalam ", body.name)
	
	if script_darah and script_darah.has_method("heal"):
		script_darah.heal(heal_amount)
		queue_free()
