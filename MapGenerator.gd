extends Node3D

@export var start_room_scene: PackedScene
@export var room_scenes: Array[PackedScene]
@export var shop_room_scene: PackedScene 
@export var forge_room_scene: PackedScene 
@export var end_room_scene: PackedScene
@export var natural_enemy_1: PackedScene # Slot lokal enemy1
@export var natural_enemy_2: PackedScene # Slot lokal enemy2

# 🔥 INTEGRASI VERSI TEMEN LU: Sistem Chest Rate Gacha
@export_group("Sistem Chest")
@export var chest_scene: PackedScene
@export_range(0.0, 1.0, 0.05) var chest_spawn_chance: float = 0.35

var wave_spawn_points: Array = []

func _ready():
	await get_tree().process_frame
	generate_level()

func generate_level():
	# 🔥 1. SAPU BERSIH SEMUA MUSUH LAMA SEBELUM GENERATE LEVEL BARU!
	hapus_semua_musuh_lama()
	
	wave_spawn_points.clear()
	
	var total_rooms = GameManager.current_level * 2 + 2
	var spawned_middle_rooms: Array = []
	var next_spawn_z: float = 0.0

	# ==================== 1. SPAWN RUANGAN START ====================
	var start_room = start_room_scene.instantiate()
	add_child(start_room)
	
	var start_gridmap = _ambil_gridmap(start_room)
	var start_bounds = _dapatkan_batas_z_gridmap(start_gridmap)
	
	start_room.global_position = Vector3(0, 0, -start_bounds["min_meter"])
	
	# 🔥 INTEGRASI: Panggil spawn chest di start room
	coba_spawn_chest_di_ruangan(start_room)
	
	var p_spawn = start_room.find_child("SpawnPoint", true, false)
	if p_spawn:
		GameManager.player_spawn_position = p_spawn.global_position
		
	next_spawn_z = start_room.global_position.z + start_bounds["max_meter"]

	# ==================== 2. SPAWN RUANGAN TENGAH ====================
	var total_middle_rooms = total_rooms - 2
	var shop_room_index = int(total_middle_rooms * 0.3)
	var forge_room_index = int(total_middle_rooms * 0.7)
	
	if shop_room_index == forge_room_index and total_middle_rooms > 1:
		forge_room_index = shop_room_index + 1

	var is_forge_level: bool = (GameManager.current_level % 2 == 0)

	for i in range(total_middle_rooms):
		var room_instance: Node3D
		
		if GameManager.is_shop_level() and i == shop_room_index and shop_room_scene != null:
			room_instance = shop_room_scene.instantiate()
			print("GENERATOR: Menyisipkan RUANG TOKO pada ruangan tengah indeks ke-", i, " di Level ", GameManager.current_level)
		elif is_forge_level and i == forge_room_index and forge_room_scene != null:
			room_instance = forge_room_scene.instantiate()
			print("GENERATOR: Menyisipkan RUANG FORGE pada ruangan tengah indeks ke-", i, " di Level ", GameManager.current_level)
		else:
			room_instance = room_scenes.pick_random().instantiate()
			
		add_child(room_instance)
		
		var current_gridmap = _ambil_gridmap(room_instance)
		var current_bounds = _dapatkan_batas_z_gridmap(current_gridmap)
		
		room_instance.global_position = Vector3(0, 0, next_spawn_z - current_bounds["min_meter"])
		
		# 🔥 INTEGRASI: Panggil spawn chest di middle room acak / spesial
		coba_spawn_chest_di_ruangan(room_instance)
		
		spawned_middle_rooms.append(room_instance)
		next_spawn_z = room_instance.global_position.z + current_bounds["max_meter"]
		
	# ==================== 3. SPAWN RUANGAN END (PORTAL) ====================
	var end_room = end_room_scene.instantiate()
	add_child(end_room)
	
	var end_gridmap = _ambil_gridmap(end_room)
	var end_bounds = _dapatkan_batas_z_gridmap(end_gridmap)
	
	end_room.global_position = Vector3(
		start_room.global_position.x, 
		start_room.global_position.y, 
		next_spawn_z - end_bounds["min_meter"]
	)
	
	print("GRIDMAP SAKTI: Ketinggian End Room dikunci di Y = ", end_room.global_position.y)

	# ==================== 4. PROSES PASCA GENERASI (SCANNING) ====================
	await get_tree().create_timer(0.1).timeout
	
	wave_spawn_points.clear()
	
	# 🔥 LOCK VERSI LOKAL: Jalankan free roam scanner musuh alami secara bersih
	_scan_natural_spawners(self)
	
	var semua_spawner_di_game = get_tree().get_nodes_in_group("WaveSpawner")
	for node in semua_spawner_di_game:
		if node is Node3D and node.is_inside_tree():
			wave_spawn_points.append(node)
			print("SISTEM SAKTI: Sukses mengunci spawner '", node.name, "' via Group Global!")

	print("GENERATOR: Berhasil mengumpulkan total spawner wave = ", wave_spawn_points.size())
	
	var active_portal = end_room.find_child("IntractivePortal", true, false)
	if not active_portal:
		active_portal = end_room.find_child("*IntractivePortal*", true, false)
		
	if active_portal:
		active_portal.spawn_points = wave_spawn_points
		active_portal.current_state = active_portal.PortalState.START_WAVE
		print("GENERATOR: Data spawner sukses disuntikkan ke dalam IntractivePortal!")
		GameManager.map_generation_complete.emit()
	else:
		push_error("Error Fatal: Tidak menemukan node 'IntractivePortal' di dalam EndRoom!")
		GameManager.map_generation_complete.emit()

# 🔥 FUNGSI SAPU BERSIH MUSUH LAMA (Mencegah Lag / Accumulation)
func hapus_semua_musuh_lama() -> void:
	var musuh_lama = get_tree().get_nodes_in_group("Enemy")
	var jumlah_terhapus = 0
	for enemy in musuh_lama:
		if is_instance_valid(enemy):
			enemy.queue_free()
			jumlah_terhapus += 1
	if jumlah_terhapus > 0:
		print("🧹 CLEANUP: Berhasil membasmi ", jumlah_terhapus, " musuh sisa dari level sebelumnya!")

# 🔥 INTEGRASI FUNGSI GACHA SPAWN CHEST DARI COMMIT BARU
func coba_spawn_chest_di_ruangan(ruangan: Node3D) -> void:
	if chest_scene == null:
		return
		
	var wadah_spawn = ruangan.find_child("ChestSpawner", true, false)
	if not wadah_spawn:
		return 
		
	var daftar_titik = wadah_spawn.get_children()
	var total_terspawn = 0
	
	for titik in daftar_titik:
		if titik is Marker3D:
			if randf() <= chest_spawn_chance:
				var chest_baru = chest_scene.instantiate()
				ruangan.add_child(chest_baru)
				
				chest_baru.global_position = titik.global_position
				chest_baru.global_rotation = titik.global_rotation
				total_terspawn += 1
				
	if total_terspawn > 0:
		print("🎁 GENERATOR CHEST: Berhasil memunculkan ", total_terspawn, " chest di ruangan '", ruangan.name, "'")

func _ambil_gridmap(node: Node) -> GridMap:
	if node is GridMap:
		return node
	for child in node.get_children():
		var hasil = _ambil_gridmap(child)
		if hasil is GridMap:
			return hasil
	return null

func _dapatkan_batas_z_gridmap(gridmap: GridMap) -> Dictionary:
	var batas = {"min_meter": 0.0, "max_meter": 0.0}
	if not gridmap:
		return batas
		
	var cells = gridmap.get_used_cells()
	if cells.is_empty():
		return batas
		
	var min_cell_z = 999999
	var max_cell_z = -999999
	
	for cell in cells:
		if cell.z < min_cell_z: min_cell_z = cell.z
		if cell.z > max_cell_z: max_cell_z = cell.z
		
	var cell_size_z = gridmap.cell_size.z
	
	if min_cell_z <= max_cell_z:
		batas["min_meter"] = min_cell_z * cell_size_z
		batas["max_meter"] = (max_cell_z + 1) * cell_size_z
		
	return batas

# 🔥 SCANNER & LIMITER DINAMIS (Naik Sesuai Level)
# 🔥 SCANNER & LIMITER DINAMIS (Base Level 1 = 50 Musuh)
func _scan_natural_spawners(_unused_node: Node = null):
	if natural_enemy_1 == null or natural_enemy_2 == null:
		push_error("Generator Error: Slot musuh natural 1 atau 2 belum diisi di Inspector!")
		return
		
	var daftar_spawner = get_tree().get_nodes_in_group("NaturalSpawner")
	print("🐾 SCANNER FREE ROAM: Ditemukan ", daftar_spawner.size(), " titik NaturalSpawner.")
	
	# 🔥 RUMUS LIMITER BARU:
	# Level 1 = 50 ekor | Level 2 = 55 ekor | Level 3 = 60 ekor ... dst.
	var base_limit = 200
	var bonus_per_level = (GameManager.current_level - 1) * 20
	var max_musuh_free_roam = base_limit + bonus_per_level
	
	print("📈 LIMITER LEVEL ", GameManager.current_level, ": Maksimal ", max_musuh_free_roam, " musuh liar di map.")
	
	var count = 0
	daftar_spawner.shuffle()
	
	for spawner in daftar_spawner:
		if spawner is Node3D and spawner.is_inside_tree():
			if count >= max_musuh_free_roam:
				print("🛑 LIMITER FREE ROAM: Kuota musuh liar level ", GameManager.current_level, " sudah penuh (", max_musuh_free_roam, " ekor).")
				break
				
			spawn_natural_monster(spawner.global_position)
			count += 1

func spawn_natural_monster(spawn_pos: Vector3):
	var terpilih_scene: PackedScene = natural_enemy_1 if randf() < 0.5 else natural_enemy_2
	if terpilih_scene == null: return
		
	var natural_enemy = terpilih_scene.instantiate()
	
	# Pastikan musuh masuk ke group "Enemy" biar gampang di-cleanup & dibatasi!
	if not natural_enemy.is_in_group("Enemy"):
		natural_enemy.add_to_group("Enemy")
		
	get_tree().current_scene.add_child(natural_enemy)
	natural_enemy.global_position = spawn_pos
	
	print("🐾 FREE ROAM: Sukses spawn musuh acak di posisi: ", spawn_pos)
