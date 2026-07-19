# ==============================================================================
# WeaponManager.gd (Full Code - Sistem 2 Slot & Deteksi Chest Pintar)
# ==============================================================================
extends Marker3D

var slot_senjata = ["", ""]
var slot_aktif = 0
var node_senjata_di_tangan : Node = null

# --- 🔥 BUFF DARI TOKO (DIPANGGIL OLEH PLAYER.GD) ---
var shop_bonus_damage: int = 0
var shop_attack_cooldown_multiplier: float = 1.0

# --- 🛠️ DAFTAR SENJATA YANG TERSEDIA ---
var daftar_senjata_terbuka = {
	"sword_slim": true,        # 🔥 SEKARANG DI-SET TRUE AGAR TERBUKA DI AWAL GAME
	"katana": false,
	"hugs": false,
	"hugs_fire": false,
	"bow": false,
	"sword_slim_nature": false
}

# --- ⚔️ DATABASE STATS FORGE (RESOURCE WEAPONDATA) ---
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
		# 🔥 PASANG SWORD_SLIM SEBAGAI SENJATA DEFAULT DI MAP PERMAINAN ASLI
		if slot_senjata[slot_aktif] == "" and daftar_senjata_terbuka["sword_slim"]:
			slot_senjata[slot_aktif] = "sword_slim"
			pasang_visual_senjata("sword_slim")
			paksa_refresh_hud_sekarang()

func _input(event: InputEvent) -> void:
	# ⚡ DETEKSI INPUT BERKUNCI DENGAN NAMA ACTION 'switch' (TOMBOL TAB)
	if event.is_action_pressed("switch"):
		var slot_baru = 1 if slot_aktif == 0 else 0
		
		# 🔥 Pindah slot dibebaskan! Slot kosong ("") tetap bisa dipilih.
		slot_aktif = slot_baru
		print("🔄 TAB Ditekan! Pindah ke Slot: ", slot_aktif + 1, " (Isi: '", slot_senjata[slot_aktif], "')")
		
		pasang_visual_senjata(slot_senjata[slot_aktif])
		paksa_refresh_hud_sekarang()

# Fungsi ini otomatis terpicu begitu tombol "BELI" di toko dipencet
func _on_weapon_bought_from_shop(weapon_id: String) -> void:
	var nama_senjata_asli = convert_id_ke_nama_file(weapon_id)
	
	if nama_senjata_asli in daftar_senjata_terbuka:
		# 1. Buka gemboknya di inventory toko
		daftar_senjata_terbuka[nama_senjata_asli] = true
		print("🔒 WEAPON MANAGER: Gembok senjata ", nama_senjata_asli, " berhasil terbuka!")
		
		# 2. Langsung PAKSA PASANG ke slot aktif sekarang (Gantiin senjata lama dari toko)
		slot_senjata[slot_aktif] = nama_senjata_asli
		pasang_visual_senjata(nama_senjata_asli)
		paksa_refresh_hud_sekarang()
		
		print("⚔️ WEAPON MANAGER: Sukses menukar slot aktif dengan senjata baru: ", nama_senjata_asli)

## Fungsi untuk menerjemahkan ID toko dari GameManager menjadi nama file .tscn kamu
func convert_id_ke_nama_file(shop_id: String) -> String:
	match shop_id:
		"wp_katana": return "katana"
		"wp_nature": return "sword_slim_nature"
		"wp_fire": return "hugs_fire"
		_: return shop_id.replace("wp_", "") 

# --- FUNGSI AMBIL SENJATA DARI CHEST (MENDUKUNG MULTI-SLOT PINTAR) ---
func ambil_senjata(nama_barang: String) -> void:
	# Buka akses otomatis agar senjata dari Chest bisa langsung diambil tanpa terkunci toko
	if nama_barang in daftar_senjata_terbuka:
		daftar_senjata_terbuka[nama_barang] = true

	# 1. Cek apakah senjata yang sama sudah ada di salah satu slot (biar gak duplikat)
	if slot_senjata[0] == nama_barang or slot_senjata[1] == nama_barang:
		print("⚔️ Chest: Kamu sudah membawa ", nama_barang, "!")
		return

	# 2. Cek apakah SLOT AKTIF yang sedang dipilih saat ini kosong
	if slot_senjata[slot_aktif] == "":
		slot_senjata[slot_aktif] = nama_barang
		print("📦 Chest: Mengisi Slot Aktif (Slot ", slot_aktif + 1, ") dengan: ", nama_barang)
		pasang_visual_senjata(nama_barang)
		paksa_refresh_hud_sekarang()
		return

	# 3. Jika slot aktif penuh, cek apakah SLOT CADANGAN kosong
	var slot_cadangan = 1 if slot_aktif == 0 else 0
	if slot_senjata[slot_cadangan] == "":
		slot_senjata[slot_cadangan] = nama_barang
		print("📦 Chest: Slot aktif penuh, memasukkan ke Slot Cadangan (Slot ", slot_cadangan + 1, "): ", nama_barang)
		# Tetap pertahankan visual senjata aktif saat ini, jangan diganti otomatis
		paksa_refresh_hud_sekarang()
		return
		
	# 4. KONDISI KEDUA SLOT PENUH: Timpa senjata di slot aktif dengan yang baru dari chest
	print("♻️ Chest: Kedua slot penuh, menukar senjata di slot aktif dengan: ", nama_barang)
	slot_senjata[slot_aktif] = nama_barang
	pasang_visual_senjata(nama_barang)
	paksa_refresh_hud_sekarang()

# FUNGSI UNTUK INPUT ANGKA MANUAL (DIPANGGIL OLEH PLAYER.GD)
func ganti_slot(nomor_slot: int) -> void:
	var indeks_baru = nomor_slot - 1
	if indeks_baru == slot_aktif:
		return
		
	slot_aktif = indeks_baru
	print("🔢 Angka Ditekan! Swapped ke Slot: ", nomor_slot, " (Isi: '", slot_senjata[slot_aktif], "')")
	
	pasang_visual_senjata(slot_senjata[slot_aktif])
	paksa_refresh_hud_sekarang()

func pasang_visual_senjata(nama_barang: String) -> void:
	# Bersihkan model senjata lama yang ada di tangan saat ini
	if node_senjata_di_tangan != null:
		node_senjata_di_tangan.queue_free()
		node_senjata_di_tangan = null
		
	# 🔥 JIKA TANGAN KOSONG (""), BERHENTI DI SINI AGAR TIDAK MEMUNCULKAN MODEL APAPUN
	if nama_barang == "":
		print("👋 Tangan kosong, visual senjata dibersihkan.")
		return
		
	var path_senjata = "res://" + nama_barang + ".tscn"
	
	if ResourceLoader.exists(path_senjata):
		var blueprint = load(path_senjata)
		var model_baru = blueprint.instantiate()
		add_child(model_baru)
		node_senjata_di_tangan = model_baru
		print("📦 Visual Senjata Berhasil Dipasang: ", path_senjata)
		
		# --- SUNTIK DATA STATS FORGE ---
		if database_stats.has(nama_barang):
			var data_stats = database_stats[nama_barang]
			if "stats" in node_senjata_di_tangan:
				node_senjata_di_tangan.stats = data_stats
				print("⚙️ WEAPON MANAGER: Berhasil menyuntikkan data stats untuk ", nama_barang)

		# --- SUNTIK DATA ATK BUFF & ATK SPEED DARI TOKO SECARA REALTIME ---
		if node_senjata_di_tangan:
			if "shop_bonus_damage" in node_senjata_di_tangan:
				node_senjata_di_tangan.shop_bonus_damage = shop_bonus_damage
			if "shop_attack_cooldown_multiplier" in node_senjata_di_tangan:
				node_senjata_di_tangan.shop_attack_cooldown_multiplier = shop_attack_cooldown_multiplier
	else:
		print("🚨 Eror: File senjata ", path_senjata, " tidak ditemukan di folder project!")
		
	# ========================================================
	# --- TWEAK PASIF SPEED KATANA (SAFE VERSION) ---
	# ========================================================
	var player = get_parent()
	if player and "speed" in player:
		player.speed = 10.0
		
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
			if "shop_bonus_damage" in node_senjata_di_tangan:
				node_senjata_di_tangan.shop_bonus_damage = shop_bonus_damage
			if "shop_attack_cooldown_multiplier" in node_senjata_di_tangan:
				node_senjata_di_tangan.shop_attack_cooldown_multiplier = shop_attack_cooldown_multiplier
				
			node_senjata_di_tangan.attack()
		else:
			print("Menyerang pake: ", slot_senjata[slot_aktif])

# ==============================================================================
# ⚡ FUNGSI REFRESH HUD UTAMA SECARA PAKSA (MEMICU ANIMASI DI ITEMSLOT)
# ==============================================================================
func paksa_refresh_hud_sekarang() -> void:
	# CARI HUD SLOT LANGSUNG: Mencari lewat Group HUD_Slot atau root secara aman
	var hud_slot = get_tree().get_first_node_in_group("HUD_Slot")
	if not hud_slot:
		hud_slot = get_tree().root.find_child("ItemSlot", true, false)
		
	# Tembak langsung fungsi untuk memutar animasi swap di item_slot.gd!
	if hud_slot and hud_slot.has_method("mainkan_animasi_tukar"):
		hud_slot.mainkan_animasi_tukar()
		print("⚡ WEAPON MANAGER: Efek swap animasi berhasil dipicu!")
	else:
		# Fallback bawaan lama jika method kustom tidak ditemukan
		var player = get_parent()
		if player and player.has_method("switch_hud_slot"):
			player.switch_hud_slot(slot_aktif + 1)
