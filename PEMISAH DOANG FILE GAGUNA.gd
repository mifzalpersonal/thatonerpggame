extends Camera3D

@export var target_node : Node3D # Drag node Player lu ke sini lewat Inspector
@export var offset : Vector3 = Vector3(0, 4.5, 5.5) # Jarak kamera dari player
@export var kecepatan_kamera : float = 5.0

func _physics_process(delta: float) -> void:
	if target_node != null:
		# Hitung posisi ideal kamera seharusnya berada
		var posisi_tujuan = target_node.global_position + offset
		
		# Geser kamera pelan-pelan (smooth glide) menggunakan lerp
		global_position = global_position.lerp(posisi_tujuan, kecepatan_kamera * delta)
