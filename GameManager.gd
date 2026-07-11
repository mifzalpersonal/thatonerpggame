extends Node

# Tempat menyimpan data Main Scene (Dinamis, awalnya null)
var main_scene = null 

var current_level: int = 1
var current_wave: int = 1
const MAX_WAVES: int = 3

# --- DATA MASTER ITEM UNTUK TOKO (Bisa kamu tambah sesuka hati) ---
var MASTER_ITEMS: Array[Dictionary] = [
	{"id": "hp_potion", "name": "Ramuan HP", "price": 20, "desc": "Pulihkan 50 HP", "icon_path":"res://SlashVFX-Asset/Demo/TextMesh Pro/Sprites/EmojiOne.png" },
	{"id": "atk_buff", "name": "Antidote ATK", "price": 45, "desc": "Attack +5 permanen", "icon_path": "res://SlashVFX-Asset/Demo/TextMesh Pro/Sprites/EmojiOne.png"},
	{"id": "speed_boots", "name": "Sepatu Gesit", "price": 35, "desc": "Speed +10%", "icon_path": "res://SlashVFX-Asset/Demo/TextMesh Pro/Sprites/EmojiOne.png"},
	{"id": "shield", "name": "Perisai Kuno", "price": 40, "desc": "Tambah Defense", "icon_path": "res://SlashVFX-Asset/Demo/TextMesh Pro/Sprites/EmojiOne.png"}
]

# --- VARIABEL BARU: SISTEM CURRENCY ---
var total_currency: int = 0

# Koordinat spawn player yang dihitung otomatis oleh Generator
var player_spawn_position: Vector3 = Vector3.ZERO

# Sinyal komunikasi antar scene
signal level_changed
signal map_generation_complete
# Sinyal baru untuk memberi tahu jika koin bertambah/berkurang
signal currency_changed(new_amount: int)

# Path menuju scene generator otomatis kamu
var generator_scene_path: String = "res://Map-Asset/Scene/procedural_map.tscn"

func load_initial_level():
	# Gunakan loop while yang aman, bukan memanggil fungsi lagi (rekursif)
	while main_scene == null:
		print("GAMEMANAGER: Menunggu main_scene siap...")
		await get_tree().process_frame
		
	var map_scene = load(generator_scene_path)
	if map_scene:
		main_scene.change_map(map_scene)

func go_to_next_level():
	current_level += 1
	current_wave = 1
	print("GAMEMANAGER: Naik ke Level: ", current_level)
	level_changed.emit() # Memancarkan sinyal level berubah jika dibutuhkan nanti
	
	if has_node("/root/SceneChanger"):
		get_node("/root/SceneChanger").change_scene_to("REGENERATE_MAP")
	else:
		# Jika tidak lewat SceneChanger, langsung eksekusi regenerasi yang aman
		execute_map_regeneration()

# Fungsi baru untuk dipanggil dari SceneChanger saat layar sudah gelap gulita
func execute_map_regeneration():
	if main_scene:
		var map_scene = load(generator_scene_path)
		if map_scene:
			main_scene.change_map(map_scene)

func load_new_level(path: String):
	var map_scene = load(path)
	if map_scene and main_scene:
		main_scene.change_map(map_scene)

# --- FUNGSI BARU: LOGIKA DROP KOIN (CHANCE 45%) ---
# Panggil fungsi ini dari script musuh tepat sebelum musuh tersebut mati/queue_free()
func register_enemy_death():
	# randf() menghasilkan angka acak desimal dari 0.0 sampai 1.0
	# 0.45 setara dengan peluang 45%
	if randf() <= 0.45:
		var poin_didapat = 10 # Jumlah koin per kill, bisa kamu sesuaikan bebas
		total_currency += poin_didapat
		currency_changed.emit(total_currency) # Umumkan kalau poin berubah
		print("DAPAT KOIN! +", poin_didapat, " | Total Poin Saat Ini: ", total_currency)
	else:
		print("Musuh Mati: Sayang sekali, tidak beruntung dapat koin (Peluang 45%)")

# --- FUNGSI BARU: CEK APAKAH INI LEVEL TOKO ---
# Mengembalikan nilai true jika level saat ini adalah kelipatan 3 (3, 6, 9, dst)
func is_shop_level() -> bool:
	return current_level % 3 == 0

# Fungsi bantuan untuk scaling status musuh tiap naik level
func get_enemy_stats(base_hp: float, base_atk: float, base_speed: float) -> Dictionary:
	var mult = 1.0 + (current_level - 1) * 0.25
	return {
		"hp": base_hp * mult, 
		"atk": base_atk * mult, 
		"speed": base_speed * 1.05
	}

func reset_game():
	current_level = 1
	current_wave = 1
	total_currency = 0 # Reset koin juga saat game diulang
	player_spawn_position = Vector3.ZERO
	print("GAMEMANAGER: Data game berhasil di-reset ke Level 1 Wave 1 dengan 0 koin!")
