extends Node

# Tempat menyimpan data Main Scene (Dinamis, awalnya null)
var main_scene = null 

var current_level: int = 1
var current_wave: int = 1
const MAX_WAVES: int = 3

# Koordinat spawn player yang dihitung otomatis oleh Generator
var player_spawn_position: Vector3 = Vector3.ZERO

# Sinyal komunikasi antar scene
signal level_changed
signal map_generation_complete

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
	
	if has_node("/root/SceneChanger"):
		get_node("/root/SceneChanger").change_scene_to("REGENERATE_MAP")
	else:
		# Jika tidak lewat SceneChanger, langsung eksekusi regenerasi yang aman
		execute_map_regeneration()
# Fungsi baru untuk dipanggil dari SceneChanger saat layar sudah gelap gulita
# GANTI fungsi ini di GameManager.gd kamu
func execute_map_regeneration():
	if main_scene:
		var map_scene = load(generator_scene_path)
		if map_scene:
			main_scene.change_map(map_scene)

func load_new_level(path: String):
	var map_scene = load(path)
	if map_scene and main_scene:
		main_scene.change_map(map_scene)

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
	player_spawn_position = Vector3.ZERO
	print("GAMEMANAGER: Data game berhasil di-reset ke Level 1 Wave 1!")
