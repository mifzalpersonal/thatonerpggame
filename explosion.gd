extends Area3D

@onready var particles: GPUParticles3D = $GPUParticles3D

func _ready() -> void:
	# Murni jalankan partikel visual es birunya aja, tanpa nunggu await atau nyari musuh lagi!
	if particles:
		particles.emitting = false
		particles.one_shot = true
		particles.emitting = true
	
	# Tunggu partikel beres meledak, baru hapus dari map
	await get_tree().create_timer(1.5).timeout
	queue_free()
