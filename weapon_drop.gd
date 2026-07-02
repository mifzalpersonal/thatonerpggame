extends RigidBody3D

@export var nama_senjata : String = "Sabit Biru"

func _ready() -> void:
	# Efek ledakan mumbul acak lu kemarin biar tetep jalan
	var arah_acak_x = randf_range(-3.0, 3.0)
	var dorongan_atas = randf_range(6.0, 8.0)
	var arah_acak_z = randf_range(-3.0, 3.0)
	apply_central_impulse(Vector3(arah_acak_x, dorongan_atas, arah_acak_z))
	
	# Connect sinyal pas badannya disenggol sesuatu
	$AmbilArea.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	# Cek apakah yang nyenggol itu si Player (Char3)
	if body is CharacterBody3D :
		# Panggil fungsi ambil_senjata yang bakal kita bikin di script player
		if body.has_method("ambil_senjata"):
			# ambil senjata ada di walk.gd
			body.ambil_senjata(nama_senjata)
			
			# Hancurkan objek pedang yang menggelinding di tanah
			queue_free()
