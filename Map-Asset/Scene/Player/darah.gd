extends Node

@export var max_hp: int = 5
@export var regen_cooldown: float = 10.0 # Waktu tunggu sebelum regen (10 detik)
@export var regen_speed: float = 1.0     # Jeda penambahan HP saat regen (tiap 1 detik)
@export var regen_amount: float = 1.0    # Jumlah HP yang bertambah setiap kali regen

var hp: float = 5.0 : set = set_hp 

@onready var game_ui = get_node_or_null("/root/Main/GUI/GameUI")

# Variabel internal untuk mengatur Timer lewat kode
var cooldown_timer: SceneTreeTimer
var is_regen_active: bool = false

func _ready() -> void:
	await get_tree().process_frame
	if game_ui != null:
		game_ui.setup_hearts(max_hp, hp)

func set_hp(value: float) -> void:
	var old_hp = hp
	hp = clamp(value, 0, max_hp)
	
	if game_ui != null:
		game_ui.update_hearts(hp)
		
	# LOGIKA DETEKSI DAMAGE:
	# Jika HP baru lebih kecil dari HP sebelumnya, artinya PLAYER KENA DAMAGE
	if hp < old_hp:
		print("Player kena damage! Reset waktu tunggu regen.")
		reset_regen_cooldown()

# Fungsi untuk mengulang kembali waktu tunggu 10 detik
func reset_regen_cooldown() -> void:
	is_regen_active = false # Matikan regen jika sedang berjalan
	
	# Buat timer baru berdurasi 10 detik
	cooldown_timer = get_tree().create_timer(regen_cooldown)
	
	# Tunggu sampai timernya habis (timeout)
	await cooldown_timer.timeout
	
	# PENGAMAN: Pastikan dalam 10 detik ini player tidak kena damage lagi
	# Kita cek apakah objek timer yang selesai ini adalah timer yang paling baru
	if cooldown_timer != null and not is_regen_active and hp < max_hp:
		start_regeneration()

# Fungsi yang berjalan ketika player sukses "aman" selama 10 detik
func start_regeneration() -> void:
	is_regen_active = true
	print("Player aman! Mulai proses regenerasi HP...")
	
	# Selama status regen aktif dan HP belum penuh, isi terus darahnya
	while is_regen_active and hp < max_hp:
		# Tambah HP player secara berkala menggunakan fungsi setter biasa
		# Gunakan 'self.hp' agar fungsi setter 'set_hp' otomatis terpicu untuk update UI
		self.hp += regen_amount
		print("Regen aktif! HP bertambah jadi: ", hp)
		
		# Beri jeda waktu (misal tiap 1 detik) sebelum menambah HP berikutnya
		await get_tree().create_timer(regen_speed).timeout
	
	# Jika HP sudah penuh, matikan status regen
	if hp >= max_hp:
		is_regen_active = false
		print("HP sudah penuh, regenerasi selesai.")
