extends Control

# Sisi Latar Belakang (Sekarang Full Screen)
@onready var preview_pivot: Node3D = $SubViewportContainer/SubViewport/GridMap/WeaponPreviewPivot

# Sisi Kanan Melayang (Sesuaikan path-nya jika posisi node berubah)
@onready var weapon_name_label: Label = $PanelKanan/VBoxContainer/WeaponNameLabel
@onready var weapon_stats_label: Label = $PanelKanan/VBoxContainer/WeaponStatsLabel
@onready var cost_label: Label = $PanelKanan/VBoxContainer/CostLabel
@onready var forge_button: Button = $PanelKanan/VBoxContainer/ForgeButton/ForgeButton
@onready var close_button: Button = $PanelKanan/VBoxContainer/CloseButton

# ==========================================
# 📦 VARIABEL DATA SENJATA
# ==========================================
var senjata_aktif: Node3D = null
var stats_senjata: Resource = null # Menggunakan Resource agar anti-parser error
var biaya_nempa: int = 100

# ==========================================
# ⚙️ SIKLUS UTAMA (LIFECYCLE)
# ==========================================
func _ready() -> void:
	# Hubungkan tombol Forge ke fungsinya secara dinamis
	if forge_button and not forge_button.pressed.is_connected(_on_forge_button_pressed):
		forge_button.pressed.connect(_on_forge_button_pressed)
	
	# Hubungkan tombol Tutup ke fungsinya secara dinamis
	if close_button and not close_button.pressed.is_connected(_on_close_button_pressed):
		close_button.pressed.connect(_on_close_button_pressed)
		
	# 🛠️ PERBAIKAN MOUSE FILTER BISA DIPENCET
	# Memaksa tombol agar bisa menerima klik mouse di Godot
	if forge_button: forge_button.mouse_filter = Control.MOUSE_FILTER_STOP
	if close_button: close_button.mouse_filter = Control.MOUSE_FILTER_STOP
		
	# Pastikan UI tersembunyi saat awal permainan
	visible = false

func _process(delta: float) -> void:
	# Efek rotasi estetik model 3D senjata di sisi kiri secara perlahan
	if preview_pivot and preview_pivot.get_child_count() > 0:
		preview_pivot.rotate_y(delta * 0.6)

# ==========================================
# 🛠️ FUNGSI UTAMA (DIPANGGIL OLEH NPC FORGE)
# ==========================================
func set_senjata_yang_akan_ditempa(node_senjata: Node3D) -> void:
	senjata_aktif = node_senjata
	stats_senjata = node_senjata.stats
	
	visible = true
	get_tree().paused = true 
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Munculkan cursor mouse
	
	# Picu pembaruan visual 3D dan teks info statistik
	update_preview_3d_senjata()
	update_tampilan_ui()
# ==========================================
# 🎥 RENDER 3D SENJATA (SISI KIRI)
# ==========================================
func update_preview_3d_senjata() -> void:
	if preview_pivot == null:
		return
		
	for child in preview_pivot.get_children():
		child.queue_free()
		
	if senjata_aktif == null:
		return
		
	var scene_path = senjata_aktif.scene_file_path
	var scene_senjata = load(scene_path)
	
	if scene_senjata:
		var kloning_senjata = scene_senjata.instantiate()
		preview_pivot.add_child(kloning_senjata)
		
		# ========================================================
		# 🎛️ PENGATURAN POSISI VISUAL SENJATA DI PANEL UI
		# ========================================================
		# 1. POSISI (Geser kiri/kanan, atas/bawah, maju/mundur dari kamera)
		# X: kanan(+)/kiri(-), Y: atas(+)/bawah(-), Z: mendekat(+)/menjauh(-)
		kloning_senjata.position = Vector3(0.0, -0.5, 0.0) 
		
		# 2. ROTASI AWAL (Kemiringan senjata pas pertama kali UI muncul)
		# Jika senjatanya berdiri tegak/terbalik, putar di sini (gunakan deg_to_rad)
		kloning_senjata.rotation = Vector3(0, deg_to_rad(0), 0)
		
		# 3. SKALA / UKURAN (Jika senjatanya terlalu raksasa atau terlalu kecil di UI)
		# Ubah angka 1.5 jika ingin lebih besar, atau 0.5 jika ingin diperkecil
		kloning_senjata.scale = Vector3(0.8,0.8,0.8)
		# ========================================================
		
		kloning_senjata.set_process(false)
		kloning_senjata.set_physics_process(false)

# ==========================================
# 🖥️ UPDATE INFORMASI TEKS (SISI KANAN)
# ==========================================
func update_tampilan_ui() -> void:
	if stats_senjata == null:
		return
		
	if weapon_name_label == null or weapon_stats_label == null or cost_label == null:
		print("🚨 ERROR UI: Ada label yang null!")
		return
		
	# Tampilkan Nama Senjata & Tingkat Forge saat ini
	weapon_name_label.text = stats_senjata.weapon_name + " (Forge +" + str(stats_senjata.forge_level) + ")"
	
	# Ambil total damage saat ini langsung lewat getter dinamis Resource
	var dmg_sekarang = stats_senjata.total_damage
	
	# Hitung simulasi damage untuk level berikutnya (+15% dari base_damage)
	var lvl_berikutnya = stats_senjata.forge_level + 1
	var dmg_berikutnya = stats_senjata.base_damage + (stats_senjata.base_damage * 0.15 * lvl_berikutnya)
	var bonus_nominal = stats_senjata.base_damage * 0.15
	
	# Tampilkan daftar statistik ke teks label tengah
# Ambil data crit dari resource senjata
	var crit_persen = stats_senjata.crit_chance * 100 # Ubah desimal (0.1) ke bentuk persen (10%)
	
	# Tampilkan daftar statistik ke teks label tengah
	weapon_stats_label.text = (
		"STATISTIK SENJATA:\n\n" +
		"• Base Damage: " + str(stats_senjata.base_damage) + "\n" +
		"• Damage Saat Ini: " + str(dmg_sekarang) + " 🔥\n" +
		"• Damage Berikutnya: " + str(dmg_berikutnya) + " ⚔️\n" +
		"• Crit Chance: " + str(crit_persen) + "% 🎯\n" +
		"• Crit Multiplier: " + str(stats_senjata.crit_multiplier) + "x ⚡\n\n" +
		"Bonus Menempa: +15% Base DMG (+" + str(bonus_nominal) + ")"
	)
	
	# Kalkulasi biaya upgrade sederhana (naik 100 koin per level forge)
	biaya_nempa = (stats_senjata.forge_level + 1) * 100 
	
	# Tampilkan info uang player saat ini dari CoinManager jika ada variabel globalnya
	if "koin" in CoinManager: # Sesuaikan dengan nama variabel koin di CoinManager-mu (misal: koin, coins, gold)
		cost_label.text = "Biaya Upgrade: " + str(biaya_nempa) + " Koin\n(Koin Kamu: " + str(CoinManager.koin) + ")"
	else:
		cost_label.text = "Biaya Upgrade: " + str(biaya_nempa) + " Koin"

# ==========================================
# 🔨 LOGIKA SIGNALS & TOMBOL INTERAKSI
# ==========================================
func _on_forge_button_pressed() -> void:
	if stats_senjata == null:
		return
		
	# Cek apakah koin player di GameManager cukup untuk menempa
	if GameManager.total_currency < biaya_nempa:
		print("❌ Koin tidak cukup untuk menempa senjata!")
		cost_label.text = "Biaya Upgrade: " + str(biaya_nempa) + " Koin\nKoin Tidak Cukup!"
		return
	
	# Potong koin di GameManager
	GameManager.total_currency -= biaya_nempa
	
	# Picu sinyal bawaan GameManager agar HUD koin di layar utama ikut ter-update otomatis
	if GameManager.has_signal("currency_changed"):
		GameManager.currency_changed.emit(GameManager.total_currency)
		
	print("💰 Koin terpotong sebesar: ", biaya_nempa, ". Sisa koin: ", GameManager.total_currency)
	
	# Naikkan level forge senjata
	stats_senjata.forge_level += 1
	print("🔨 Upgrade Sukses! " + stats_senjata.weapon_name + " naik ke Forge +" + str(stats_senjata.forge_level))
	
	# Segera perbarui layar UI agar angka koin dan statistik berubah secara realtime
	update_tampilan_ui()

func _on_close_button_pressed() -> void:
	visible = false
	get_tree().paused = false 
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Sembunyikan cursor lagi

func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact")):
		_on_close_button_pressed()
