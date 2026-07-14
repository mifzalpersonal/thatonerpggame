extends Marker3D

var slot_senjata = ["", ""]
var slot_aktif = 0
var node_senjata_di_tangan : Node = null

# --- 🛠️ DAFTAR SENJATA YANG TERSEDIA ---
var daftar_senjata_terbuka = {
	"sword_slim": false,
	"katana": false,
	"hugs": false,
	"hugs_fire": true,
	"bow": false,
	"sword_slim_nature": false
}

# --- ⚔️ DATABASE STATS FORGE (RESOURCE WEAPONDATA) ---
# Menghubungkan nama senjata dengan file Resource (.tres) masing-masing.
# Pastikan kamu sudah membuat file-file .tres ini di folder "res://Weapons/" !
var database_stats = {
	"sword_slim": preload("res://Weapons/sword_slim.tres"),
	"katana": preload("res://Weapons/katana.tres"),
	"hugs": preload("res://Weapons/hugs.tres"),
	"hugs_fire": preload("res://Weapons/hugs_fire.tres"),
	"bow": preload("res://Weapons/bow.tres"),
	"sword_slim_nature": preload("res://Weapons/sword_slim_nature.tres")
}

var senjata_sekarang : String:
	get:
		return slot_senjata[slot_aktif]

func _ready() -> void:
	# Hubungkan WeaponManager ke sinyal global GameManager saat toko berhasil menjual senjata
	if GameManager.has_signal("weapon_unlocked"):
		GameManager.weapon_unlocked.connect(_on_weapon_bought_from_shop)
		
	# Cek scene saat ini. Jika di lobi / main menu, JANGAN pasang senjata dulu!
	var current_scene_name = get_tree().current_scene.name.to_lower()
	if "lobby" in current_scene_name or "menu" in current_scene_name:
		print("🏠 WEAPON MANAGER: Di lobi, menyembunyikan senjata.")
		slot_senjata = ["", ""]
		if node_senjata_di_tangan != null:
			node_senjata_di_tangan.queue_free()
	else:
		# Pasang senjata default hanya jika sudah masuk ke map permainan asli
		if slot_senjata[slot_aktif] == "" and daftar_senjata_terbuka["hugs_fire"]:
			slot_senjata[slot_aktif] = "hugs_fire"
			pasang_visual_senjata("hugs_fire")

# Fungsi ini otomatis terpicu begitu tombol "BELI" di toko dipencet
func _on_weapon_bought_from_shop(weapon_id: String) -> void:
	var nama_senjata_asli = convert_id_ke_nama_file(weapon_id)
	
	if nama_senjata_asli in daftar_senjata_terbuka:
		# 1. Buka gemboknya di inventory toko
		daftar_senjata_terbuka[nama_senjata_asli] = true
		print("🔒 WEAPON MANAGER: Gembok senjata ", nama_senjata_asli, " berhasil terbuka!")
		
		# 2. langsung PAKSA PASANG ke slot aktif sekarang (Gantiin senjata lama dari toko)
		slot_senjata[slot_aktif] = nama_senjata_asli
		pasang_visual_senjata(nama_senjata_asli)
		
		print("⚔️ WEAPON MANAGER: Sukses menukar slot aktif dengan senjata baru: ", nama_senjata_asli)

## Fungsi untuk menerjemahkan ID toko dari GameManager menjadi nama file .tscn kamu
func convert_id_ke_nama_file(shop_id: String) -> String:
	match shop_id:
		"wp_katana": return "katana"
		"wp_nature": return "sword_slim_nature"
		"wp_fire": return "hugs_fire"
		_: return shop_id.replace("wp_", "") 

# --- FUNGSI AMBIL SENJATA (DIPAKAI OLEH CHEST / PETI DI GUA) ---
func ambil_senjata(nama_barang: String) -> void:
	# Buka akses otomatis agar senjata dari Chest bisa langsung diambil tanpa terkunci toko
	if nama_barang in daftar_senjata_terbuka:
		daftar_senjata_terbuka[nama_barang] = true

	# Jika slot aktif kosong, langsung isi dan pasang visualnya
	if slot_senjata[slot_aktif] == "":
		slot_senjata[slot_aktif] = nama_barang
		print("Slot ", slot_aktif + 1, " diisi: ", nama_barang)
		pasang_visual_senjata(nama_barang)
		return
		
	# Jika slot aktif penuh, cek slot cadangan
	var slot_cadangan = 1 if slot_aktif == 0 else 0
	
	if slot_senjata[slot_cadangan] == "":
		slot_senjata[slot_cadangan] = nama_barang
		print("Slot aktif penuh, dimasukkan ke Slot ", slot_cadangan + 1, ": ", nama_barang)
		return
	else:
		# Jika kedua slot penuh, ganti senjata di slot aktif dengan yang baru dari chest
		print("Kedua slot penuh, menukar senjata di slot aktif dengan: ", nama_barang)
		slot_senjata[slot_aktif] = nama_barang
		pasang_visual_senjata(nama_barang)

func ganti_slot(nomor_slot: int) -> void:
	var indeks_baru = nomor_slot - 1
	if indeks_baru == slot_aktif:
		return
		
	slot_aktif = indeks_baru
	print("Swapped ke Slot: ", nomor_slot)
	pasang_visual_senjata(slot_senjata[slot_aktif])

func pasang_visual_senjata(nama_barang: String) -> void:
	if node_senjata_di_tangan != null:
		node_senjata_di_tangan.queue_free()
		node_senjata_di_tangan = null
		
	if nama_barang == "":
		return
		
	var path_senjata = "res://" + nama_barang + ".tscn"
	
	if ResourceLoader.exists(path_senjata):
		var blueprint = load(path_senjata)
		var model_baru = blueprint.instantiate()
		add_child(model_baru)
		node_senjata_di_tangan = model_baru
		print("📦 Visual Senjata Berhasil Dipasang: ", path_senjata)
		
		# --- SUNTIK DATA STATS FORGE KE SENJATA YANG BARU DIPASANG ---
		if database_stats.has(nama_barang):
			var data_stats = database_stats[nama_barang]
			if "stats" in node_senjata_di_tangan:
				node_senjata_di_tangan.stats = data_stats
				print("⚙️ WEAPON MANAGER: Berhasil menyuntikkan data stats untuk ", nama_barang)
	else:
		print("🚨 Eror: File senjata ", path_senjata, " tidak ditemukan di folder project!")
		
	# ========================================================
	# --- TWEAK PASIF SPEED KATANA (SAFE VERSION) ---
	# ========================================================
	var player = get_parent()
	if player and "speed" in player:
		player.speed = 10.0 # Set speed default player kamu
		
		if nama_barang == "katana":
			if player.has_method("apply_speed_boost"):
				player.apply_speed_boost(2.0, 99999.0)
				print("Base speed dinaikkan karena memegang Katana!")
		else:
			var timer_boost = player.get_node_or_null("speed_boost_timer")
			if timer_boost != null and timer_boost.has_method("is_stopped"):
				if not timer_boost.is_stopped():
					timer_boost.stop()
			
			if player.has_method("_on_speed_boost_timeout"):
				player._on_speed_boost_timeout()
	# ========================================================

func eksekusi_menyerang() -> void:
	if slot_senjata[slot_aktif] != "":
		# Pemicu fungsi attack() di script senjata masing-masing secara otomatis
		if node_senjata_di_tangan and node_senjata_di_tangan.has_method("attack"):
			node_senjata_di_tangan.attack()
		else:
			print("Menyerang pake: ", slot_senjata[slot_aktif])
