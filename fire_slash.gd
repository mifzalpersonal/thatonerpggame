extends BaseSlash

# Di sini kita hanya perlu mengatur data/spesifikasi unik untuk slash ini saja.
# Semua logika pergerakan, deteksi player, scaling, dan damage otomatis diwarisi dari BaseSlash!

func _init() -> void:
	speed = 2.5
	damage = 70
	lifetime = 2.5
	
	# Mengatur ukuran scaling yang spesifik untuk slash ini
	scale_awal = Vector3(5, 5, 5)
	scale_tengah = Vector3(20, 20, 20)
	scale_akhir = Vector3(15, 15, 15)

# Tulis efek mekanik unik (misalnya memberikan efek Burn) di sini
func _terapkan_efek_unik(body: Node, damage_terhitung: float) -> void:
	if body.has_method("apply_burn_stack"):
		body.apply_burn_stack(damage_terhitung)
		print("🔥 [Slash] Memberi efek Burn Stack ke musuh dengan basis damage: ", damage_terhitung)
