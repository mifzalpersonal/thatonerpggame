extends Area3D

@export var slow_duration: float = 4.0
@export var slow_percentage: float = 0.6 # Mengurangi speed sebesar 60%

@onready var particles: GPUParticles3D = $GPUParticles3D

func _ready() -> void:
	# Nyalakan partikel salju/es
	if particles:
		particles.one_shot = true
		particles.emitting = true
	
	# Tunggu physics frame sedikit agar fungsi get_overlapping_bodies() akurat
	await get_tree().create_timer(0.05).timeout
	
	# Ambil semua objek yang berada di dalam area lingkaran ledakan
	var targets = get_overlapping_bodies()
	
	for body in targets:
		# Jika objek yang kena adalah musuh dan punya fungsi apply_freeze_slow
		if (body is BaseEnemy or body.is_in_group("enemy")) and body.has_method("apply_freeze_slow"):
			body.apply_freeze_slow(slow_percentage, slow_duration)
	
	# Tunggu sampai durasi partikel selesai (misal 1.5 detik) baru hapus ledakannya
	await get_tree().create_timer(1.5).timeout
	queue_free()
