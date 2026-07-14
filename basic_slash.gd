extends BaseSlash

# Ini adalah skrip untuk tebasan biasa (Basic Slash) kamu.
# Semua pergerakan, scaling, dan hitungan damage otomatis diurus oleh BaseSlash!

func _init() -> void:
	speed = 2.5
	damage = 10
	lifetime = 2.5
	
	# Skala bawaan untuk Basic Slash
	scale_awal = Vector3(5, 5, 5)
	scale_tengah = Vector3(20, 20, 20)
	scale_akhir = Vector3(15, 15, 15)

# Karena ini tebasan biasa tanpa efek unik (no burn, no freeze, dll),
# kita tidak perlu menulis fungsi _terapkan_efek_unik() di sini.
# Dia akan otomatis melewati fungsi kosong yang ada di BaseSlash!
