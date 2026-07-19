extends Node3D

@export var start_room_scene: PackedScene
@export var room_scenes: Array[PackedScene]
@export var shop_room_scene: PackedScene # Slot untuk memasukkan shop_room.tscn
@export var forge_room_scene: PackedScene # Slot untuk memasukkan ForgeRoom.tscn di Inspector
@export var end_room_scene: PackedScene
@export var natural_enemy_scene: PackedScene 

# --- PENGATURAN RATE CHEST DI INSPECTOR ---
@export_group("Sistem Chest")
@export var chest_scene: PackedScene ## Seret scene Chest.tscn kamu ke sini
@export_range(0.0, 1.0, 0.05) var chest_spawn_chance: float = 0.35 ## Mengatur rate/peluang spawn (0.0 = 0%, 1.0 = 100%)

var wave_spawn_points: Array = []

func _ready():
	await get_tree().process_frame
	generate_level()

func generate_level():
	wave_spawn_points.clear()
	
	var total_rooms = GameManager.current_level * 2 + 2
	var spawned_middle_rooms: Array = []

	# Titik pasang berikutnya dalam koordinat METER dunia global
	var next_spawn_z: float = 0.0

	# ==================== 1. SPAWN RUANGAN START ====================
	var start_room = start_room_scene.instantiate()
	add_child(start_room)
	
	var start_gridmap = _ambil_gridmap(start_room)
	var start_bounds = _dapatkan_batas_z_gridmap(start_gridmap)
	
	# Posisikan agar bagian depan ubin start_room berada di Z = 0
	start_room.global_position = Vector3(0, 0, -start_bounds["min_meter"])
	
	# 🔥 SPAWN CHEST DI START ROOM (Mencari node ChestSpawner)
	coba_spawn_chest_di_ruangan(start_room)
	
	var p_spawn = start_room.find_child("SpawnPoint", true, false)
	if p_spawn:
		GameManager.player_spawn_position = p_spawn.global_position
		
	# Tentukan titik pasang berikutnya tepat di ujung ubin paling belakang start_room
	next_spawn_z = start_room.global_position.z + start_bounds["max_meter"]

	# ==================== 2. SPAWN RUANGAN TENGAH (TERMASUK SHOP & FORGE) ====================
	var total_middle_rooms = total_rooms - 2
	
	# Tentukan indeks posisi ruangan spesial secara proporsional
	var shop_room_index = int(total_middle_rooms * 0.3)
	var forge_room_index = int(total_middle_rooms * 0.7)
	
	# Antisipasi jika ruangan terlalu sedikit agar indeksnya tidak tabrakan
	if shop_room_index == forge_room_index and total_middle_rooms > 1:
		forge_room_index = shop_room_index + 1

	# Fitur Baru: Cek apakah level saat ini adalah kelipatan 4 untuk ForgeArea
	var is_forge_level: bool = (GameManager.current_level % 2 == 0)

	for i in range(total_middle_rooms):
		var room_instance: Node3D
		
		# KONDISI A: Jika ini level kelipatan 3 dan menyentuh indeks toko, lahirkan TOKO
		if GameManager.is_shop_level() and i == shop_room_index and shop_room_scene != null:
			room_instance = shop_room_scene.instantiate()
			print("GENERATOR: Menyisipkan RUANG TOKO pada ruangan tengah indeks ke-", i, " di Level ", GameManager.current_level)
			
		# KONDISI B: Jika ini level kelipatan 4 dan menyentuh indeks forge, lahirkan FORGE
		elif is_forge_level and i == forge_room_index and forge_room_scene != null:
			room_instance = forge_room_scene.instantiate()
			print("GENERATOR: Menyisipkan RUANG FORGE pada ruangan tengah indeks ke-", i, " di Level ", GameManager.current_level)
			
		else:
			# Jika bukan ruangan spesial, lahirkan ruangan acak biasa
			room_instance = room_scenes.pick_random().instantiate()
			
		add_child(room_instance)
		
		var current_gridmap = _ambil_gridmap(room_instance)
		var current_bounds = _dapatkan_batas_z_gridmap(current_gridmap)
		
		# Tempelkan ujung ubin depan ruangan baru ke ujung ubin belakang ruangan sebelumnya
		room_instance.global_position = Vector3(0, 0, next_spawn_z - current_bounds["min_meter"])
		
		# 🔥 SPAWN CHEST DI RUANGAN TENGAH/SPESIAL INI
		coba_spawn_chest_di_ruangan(room_instance)
		
		spawned_middle_rooms.append(room_instance)
		
		# Perbarui titik pasang untuk ruangan berikutnya
		next_spawn_z = room_instance.global_position.z + current_bounds["max_meter"]
		
	# ==================== 3. SPAWN RUANGAN END (PORTAL) ====================
	var end_room = end_room_scene.instantiate()
	add_child(end_room)
	
	var end_gridmap = _ambil_gridmap(end_room)
	var end_bounds = _dapatkan_batas_z_gridmap(end_gridmap)
	
	# PERBAIKAN: Kunci sumbu Y agar SELALU SAMA dengan start_room
	end_room.global_position = Vector3(
		start_room.global_position.x, 
		start_room.global_position.y, 
		next_spawn_z - end_bounds["min_meter"]
	)
	
	# 🛑 PEMBERHENTIAN: Di sini kita TIDAK memanggil coba_spawn_chest_di_ruangan(end_room)
	# Sehingga End Room dijamin bersih dari chest acak.
	
	print("GRIDMAP SAKTI: Ketinggian End Room dikunci di Y = ", end_room.global_position.y)

	# ==================== 4. PROSES PASCA GENERASI (SCANNING) ====================
	await get_tree().create_timer(0.1).timeout
	
	wave_spawn_points.clear()
	
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

# --- 📦 FUNGSI GACHA SPAWN CHEST ---
func coba_spawn_chest_di_ruangan(ruangan: Node3D) -> void:
	if chest_scene == null:
		return
		
	# 🔍 DITWEAK: Mencari "ChestSpawner" sesuai struktur nama node kamu
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
		print("📦 GENERATOR CHEST: Berhasil memunculkan ", total_terspawn, " chest di ruangan '", ruangan.name, "'")

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

func _sortir_spawner_pakai_group(node: Node):
	if node and node is Node3D:
		if node.is_in_group("WaveSpawner"):
			wave_spawn_points.append(node)
			print("GENERATOR SAKTI: Nemu spawner '", node.name, "' di posisi: ", node.global_position)
			
		elif node.is_in_group("NaturalSpawner"):
			spawn_natural_monster(node.global_position, node)

	if node:
		for child in node.get_children():
			_sortir_spawner_pakai_group(child)

func spawn_natural_monster(spawn_pos: Vector3, room_parent: Node3D):
	if natural_enemy_scene == null or not is_instance_valid(room_parent): return
	var natural_enemy = natural_enemy_scene.instantiate()
	room_parent.add_child(natural_enemy)
	natural_enemy.global_position = spawn_pos
