extends Node

# Sinyal global untuk memberi tahu WeaponManager saat senjata dibeli
signal weapon_unlocked(weapon_id: String)

# Tempat menyimpan data Main Scene (Dinamis, awalnya null)
var main_scene = null 

var current_level: int = 1
var current_wave: int = 1
const MAX_WAVES: int = 3

# --- DATA MASTER ITEM TOKO DENGAN RARITY ---
var MASTER_ITEMS: Array[Dictionary] = [
	{"id": "hp_potion", "name": "Ramuan HP", "price": 20, "desc": "Pulihkan 50 HP", "rarity": "common", "icon_path": "res://SlashVFX-Asset/Demo/TextMesh Pro/Sprites/EmojiOne.png"},
	{"id": "speed_boots", "name": "Sepatu Gesit", "price": 35, "desc": "Speed +10%", "rarity": "common", "icon_path": "res://SlashVFX-Asset/Demo/TextMesh Pro/Sprites/EmojiOne.png"},
	{"id": "atk_buff", "name": "Antidote ATK", "price": 45, "desc": "Attack +5", "rarity": "rare", "icon_path": "res://SlashVFX-Asset/Demo/TextMesh Pro/Sprites/EmojiOne.png"},
	{"id": "atk_speed_buff", "name": "Cincin Waktu", "price": 40, "desc": "Atk Speed +15%", "rarity": "rare", "icon_path": "res://SlashVFX-Asset/Demo/TextMesh Pro/Sprites/EmojiOne.png"},
	{"id": "hugs", "name": "Hugs Normal", "price": 100, "desc": "Buka senjata Hugs standar", "rarity": "common", "icon_path": "res://SlashVFX-Asset/Demo/TextMesh Pro/Sprites/EmojiOne.png"},
	{"id": "bow", "name": "Busur Panah", "price": 255, "desc": "Buka senjata Bow", "rarity": "rare", "icon_path": "res://bowace.png"},
	{"id": "wp_fire", "name": "Hugs Fire Blaster", "price": 333, "desc": "Buka Hugs Fire (DoT Burn)", "rarity": "rare", "icon_path": "res://sword3.png"},
	{"id": "wp_nature", "name": "Tongkat Nature", "price": 300, "desc": "Buka Nature (Efek Slow)", "rarity": "rare", "icon_path": "res://Sword2.png"},
	{"id": "wp_katana", "name": "Katana Terkutuk", "price": 1000, "desc": "Buka Katana (Lifesteal)", "rarity": "legendary", "icon_path": "res://Katana.png"}
]

# Variabel untuk mengunci isi toko saat ini agar tidak berubah-ubah tiap dibuka-tutup
var isi_toko_level_ini: Array[Dictionary] = []

# --- VARIABEL: SISTEM CURRENCY & REROLL DINAMIS ---
var total_currency: int = 99999 
const HARGA_REROLL_BASE: int = 10     # Harga awal setiap ganti toko baru
var harga_reroll_sekarang: int = 10   # Harga berjalan yang akan naik dikali 2
const MAX_HARGA_REROLL: int = 200     # Batas harga maksimal reroll

# Koordinat spawn player yang dihitung otomatis oleh Generator
var player_spawn_position: Vector3 = Vector3.ZERO

# --- SINYAL KOMUNIKASI ---
signal level_changed
signal map_generation_complete
signal currency_changed(new_amount: int)
signal item_purchased(item_id: String)
signal tampilkan_ui_wave(status: bool)

# Path menuju scene generator otomatis kamu
var generator_scene_path: String = "res://Map-Asset/Scene/procedural_map.tscn"

func _ready() -> void:
	buat_rak_toko_baru()

# ==============================================================================
# 🎯 FUNGSI GLOBAL SUNTIK DAMAGE DENGAN INTEGRASI RARITY FORGE SYSTEM
# ==============================================================================
func siapkan_peluru(slash_instance: Node, stats: WeaponData, bonus_damage: int) -> void:
	if stats == null:
		print("🚨 GAMEMANAGER: Gagal siapkan peluru karena WeaponData kosong!")
		return
		
	var hasil_kocokan = stats.hitung_damage_output()
	var damage_kocokan = stats.total_damage + (hasil_kocokan["damage"] - stats.base_damage)
	var apakah_crit = hasil_kocokan["is_critical"]
	
	var total_damage_akhir = damage_kocokan + bonus_damage
	
	if "damage" in slash_instance:
		slash_instance.damage = total_damage_akhir
		
	if "is_critical" in slash_instance:
		slash_instance.is_critical = apakah_crit
		
	print("⚔️ SYSTEM FORGE: ", stats.weapon_name, " [Rarity: ", stats.get_rarity_name(), "] (Level +", stats.forge_level, ")")
	if apakah_crit:
		print("    └─ 💥 CRITICAL HIT! Total Damage disuntik: ", total_damage_akhir)
	else:
		print("    └─ Normal Damage disuntik: ", total_damage_akhir)


# --- LOGIKA GENERATOR BARANG (GARANSI PASTI TEPAT 4 SLOT UNIK) ---
func buat_rak_toko_baru() -> void:
	isi_toko_level_ini.clear()
	harga_reroll_sekarang = HARGA_REROLL_BASE
	print("🎲 GAMEMANAGER: Toko baru didirikan. Harga reroll di-reset kembali ke: ", harga_reroll_sekarang)
	
	var item_common: Array[Dictionary] = []
	var item_rare: Array[Dictionary] = []
	var item_legendary: Array[Dictionary] = []
	
	for item in MASTER_ITEMS:
		if item["rarity"] == "common": item_common.append(item)
		elif item["rarity"] == "rare": item_rare.append(item)
		elif item["rarity"] == "legendary": item_legendary.append(item)
		
	var safety_break = 0 
	while isi_toko_level_ini.size() < 4 and safety_break < 100:
		safety_break += 1
		var dadu = randf() 
		var item_terpilih: Dictionary = {}
		
		if dadu <= 0.10 and item_legendary.size() > 0: 
			item_terpilih = item_legendary[randi() % item_legendary.size()]
		elif dadu <= 0.40 and item_rare.size() > 0: 
			item_terpilih = item_rare[randi() % item_rare.size()]
		else: 
			if item_common.size() > 0:
				item_terpilih = item_common[randi() % item_common.size()]
			else:
				if MASTER_ITEMS.size() > 0:
					item_terpilih = MASTER_ITEMS[randi() % MASTER_ITEMS.size()]
				
		if not item_terpilih.is_empty() and not isi_toko_level_ini.has(item_terpilih):
			isi_toko_level_ini.append(item_terpilih)
			
	print("🛒 GAMEMANAGER: Rak toko dikunci. Total item unik: ", isi_toko_level_ini.size(), "/4")

# --- MEKANIK REQUEST REROLL ---
func request_reroll() -> bool:
	if total_currency >= harga_reroll_sekarang:
		total_currency -= harga_reroll_sekarang
		currency_changed.emit(total_currency)
		
		acak_tanpa_reset_biaya()
		harga_reroll_sekarang = clampi(harga_reroll_sekarang * 2, HARGA_REROLL_BASE, MAX_HARGA_REROLL)
		
		print("🎲 GAMEMANAGER: Reroll sukses! Biaya reroll selanjutnya naik menjadi: ", harga_reroll_sekarang, " Koin.")
		return true
		
	print("GAMEMANAGER: Koin tidak cukup untuk melakukan reroll!")
	return false

func acak_tanpa_reset_biaya() -> void:
	isi_toko_level_ini.clear()
	var item_common: Array[Dictionary] = []
	var item_rare: Array[Dictionary] = []
	var item_legendary: Array[Dictionary] = []
	
	for item in MASTER_ITEMS:
		if item["rarity"] == "common": item_common.append(item)
		elif item["rarity"] == "rare": item_rare.append(item)
		elif item["rarity"] == "legendary": item_legendary.append(item)
		
	var safety_break = 0 
	while isi_toko_level_ini.size() < 4 and safety_break < 100:
		safety_break += 1
		var dadu = randf()
		var item_terpilih: Dictionary = {}
		
		if dadu <= 0.10 and item_legendary.size() > 0: item_terpilih = item_legendary[randi() % item_legendary.size()]
		elif dadu <= 0.40 and item_rare.size() > 0: item_terpilih = item_rare[randi() % item_rare.size()]
		else:
			if item_common.size() > 0: item_terpilih = item_common[randi() % item_common.size()]
			else: item_terpilih = MASTER_ITEMS[randi() % MASTER_ITEMS.size()]
				
		if not item_terpilih.is_empty() and not isi_toko_level_ini.has(item_terpilih):
			isi_toko_level_ini.append(item_terpilih)

# --- SISTEM PEMBELIAN & SELEKSI EFEK ITEM TOKO ---
func buy_item(item: Dictionary) -> bool:
	var harga = item["price"]
	var item_id = item["id"]
	
	if total_currency >= harga:
		total_currency -= harga
		currency_changed.emit(total_currency)
		
		if item_id.begins_with("wp_") or item_id in ["katana", "hugs", "bow"]:
			weapon_unlocked.emit(item_id)
			print("⚔️ GAMEMANAGER: Berhasil buka gembok senjata: ", item["name"])
		else:
			item_purchased.emit(item_id)
			print("📦 GAMEMANAGER: Berhasil membeli item status: ", item["name"])
		return true
	return false

# --- MAP MANAGEMENT & REGENERATION ---
func load_initial_level():
	while main_scene == null:
		await get_tree().process_frame
	var map_scene = load(generator_scene_path)
	if map_scene: main_scene.change_map(map_scene)

func go_to_next_level():
	current_level += 1
	current_wave = 1
	level_changed.emit()
	if has_node("/root/SceneChanger"):
		get_node("/root/SceneChanger").change_scene_to("REGENERATE_MAP")
	else:
		execute_map_regeneration()

func execute_map_regeneration():
	if main_scene:
		var map_scene = load(generator_scene_path)
		if map_scene: main_scene.change_map(map_scene)
	buat_rak_toko_baru()

func load_new_level(path: String):
	var map_scene = load(path)
	if map_scene and main_scene: main_scene.change_map(map_scene)

func register_enemy_death():
	if randf() <= 0.45:
		total_currency += 10
		currency_changed.emit(total_currency)

# Toko aktif setiap kelipatan 3 level
func is_shop_level() -> bool:
	return current_level % 3 == 0

# BARU: ForgeArea aktif setiap kelipatan 4 level
func is_forge_level() -> bool:
	return current_level % 2 == 0

func get_enemy_stats(base_hp: float, base_atk: float, base_speed: float) -> Dictionary:
	var mult = 1.0 + (current_level - 1) * 0.25
	return {"hp": base_hp * mult, "atk": base_atk * mult, "speed": base_speed * 1.05}

func maju_ke_wave_selanjutnya() -> void:
	if current_wave < MAX_WAVES:
		current_wave += 1
		level_changed.emit()
		print("⚔️ GAMEMANAGER: Bersiap! Masuk ke Wave: ", current_wave)
	else:
		print("🏆 GAMEMANAGER: Semua Wave di level ini selesai!")
		go_to_next_level()

func reset_game():
	current_level = 1
	current_wave = 1
	total_currency = 0
	player_spawn_position = Vector3.ZERO
	buat_rak_toko_baru()
	level_changed.emit()

# ==============================================================================
# 🎲 MEKANIK UPGRADE RARITY FORGE DENGAN SISTEM GACHA ACAK CHANCE INSPECTOR
# ==============================================================================
func upgrade_weapon_rarity(weapon_stats: WeaponData) -> bool:
	if weapon_stats == null:
		print("🚨 GAMEMANAGER: Gagal upgrade karena WeaponData kosong!")
		return false
		
	var kocokan: float = randf() 
	var rarity_baru: int = 0
	
	var p_common = weapon_stats.chance_common
	var p_uncommon = p_common + weapon_stats.chance_uncommon
	var p_rare = p_uncommon + weapon_stats.chance_rare
	var p_epic = p_rare + weapon_stats.chance_epic
	
	if kocokan < p_common:
		rarity_baru = 0
	elif kocokan < p_uncommon:
		rarity_baru = 1
	elif kocokan < p_rare:
		rarity_baru = 2
	elif kocokan < p_epic:
		rarity_baru = 3
	else:
		rarity_baru = 4
		
	weapon_stats.current_rarity = rarity_baru as WeaponData.Rarity
	
	print("🎲 [GameManager] GACHA BERHASIL!")
	print("    └─ Senjata    : ", weapon_stats.weapon_name)
	print("    └─ Kasta Baru : ", weapon_stats.get_rarity_name())
	print("    └─ Total DMG  : ", weapon_stats.total_damage)
	return true

func set_weapon_rarity_langsung(weapon_stats: WeaponData, rarity_baru: WeaponData.Rarity) -> void:
	if weapon_stats != null:
		weapon_stats.current_rarity = rarity_baru
		print("💎 RARITY SET: ", weapon_stats.weapon_name, " diubah menjadi ", weapon_stats.get_rarity_name())
