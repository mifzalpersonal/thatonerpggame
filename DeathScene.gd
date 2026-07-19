extends Control

# Menyambungkan otomatis ke node bernama "Button" di dalam scene
@onready var tombol_respawn: Button = $Button

func _ready() -> void:
	# Memastikan tombolnya ketemu sebelum disambungkan
	if tombol_respawn:
		# Menghubungkan sinyal klik tombol ke fungsi di bawah secara otomatis
		tombol_respawn.pressed.connect(_on_tombol_respawn_pressed)
		print("Sistem Respawn: Tombol berhasil terdeteksi dan dihubungkan!")
	else:
		push_error("Sistem Respawn: Node bernama 'Button' tidak ditemukan! Periksa kembali nama nodemu.")

func _on_tombol_respawn_pressed() -> void:
	print("Tombol diklik! Mencoba berpindah ke Main.tscn...")
	
	# Berpindah ke scene utama kamu
	var error_code = get_tree().change_scene_to_file("res://Map-Asset/Scene/Main.tscn")
	
	# Kode pengaman untuk mengecek jika file Main.tscn tidak ditemukan
	if error_code != OK:
		print("Gagal pindah scene! Ketemu error kode: ", error_code)
		print("Penyebab utama biasanya karena letak file 'Main.tscn' tidak langsung di luar, atau salah ketik huruf besar/kecil.")
