extends Node3D

@export var start_room_scene: PackedScene
@export var room_scenes: Array[PackedScene] # Variasi ruangan tengah
@export var end_room_scene: PackedScene

# Slot untuk menentukan monster yang langsung ada di map secara alami
@export var natural_enemy_scene: PackedScene 

# Ukuran ubin/lantai ruangan kamu (misal: 20x20 meter)
const ROOM_SIZE: float = 20.0

# Tempat menampung data spawner KHUSUS WAVE untuk dikirim ke portal
var wave_spawn_points: Array = []

func _ready():
	# Beri jeda 1 frame agar seluruh sistem siap, baru buat map
	await get_tree().process_frame
	generate_level()

func generate_level():
	# Bersihkan data lama tiap kali naik level
	wave_spawn_points.clear()
	
	# Rumus panjang map: Level 1 = 4 ruangan, Level 2 = 6 ruangan, dst.
	var total_rooms = GameManager.current_level * 2 + 2
	var current_position = Vector3.ZERO

	# ==================== 1. SPAWN RUANGAN START ====================
	var start_room = start_room_scene.instantiate()
	add_child(start_room)
	start_room.global_position = current_position
	
	# Ambil koordinat GLOBAL untuk posisi awal player
	var p_spawn = start_room.find_child("SpawnPoint", true, false)
	if p_spawn:
		GameManager.player_spawn_position = p_spawn.global_position
	
	current_position.z -= ROOM_SIZE
	
	# ==================== 2. SPAWN RUANGAN TENGAH ====================
	for i in range(total_rooms - 2):
		var room_instance = room_scenes.pick_random().instantiate()
		
		# Masukkan dulu ke dunia & atur posisinya
		add_child(room_instance)
		room_instance.global_position = current_position
		
		# Beri jeda 1 frame tipis agar transformasi koordinat dihitung oleh engine
		await get_tree().process_frame
		
		# Scan spawner di dalam ruangan menggunakan sistem Group
		_sortir_spawner_pakai_group(room_instance)
		
		current_position.z -= ROOM_SIZE
		
	# ==================== 3. SPAWN RUANGAN END (PORTAL) ====================
	var end_room = end_room_scene.instantiate()
	add_child(end_room)
	end_room.global_position = current_position
	
	# Cari node InteractivePortal di dalam ruangan terakhir
	var active_portal = end_room.find_child("InteractivePortal", true, false)
	
	if active_portal:
		# Kirim daftar titik spawn WAVE yang sudah disaring ke script portal
		active_portal.spawn_points = wave_spawn_points
		
		# Beri jeda 1 frame agar posisi fisik/global di-update oleh engine
		await get_tree().process_frame
		
		# Kabari Main Scene bahwa proses bangun map sudah selesai!
		GameManager.map_generation_complete.emit()
	else:
		push_error("Error Fatal: Tidak menemukan node 'InteractivePortal' di dalam EndRoom!")

# Fungsi rekursif untuk menyaring spawner berdasarkan Group Godot
func _sortir_spawner_pakai_group(node: Node):
	for child in node.get_children():
		if child is Marker3D:
			# A. Jika masuk dalam group WaveSpawner, kumpulkan untuk Portal
			if child.is_in_group("WaveSpawner"):
				wave_spawn_points.append(child)
				print("SISTEM GENERATOR: Terdaftar spawner WAVE baru: ", child.name)
				
			# B. Jika masuk dalam group NaturalSpawner, langsung lahirkan sekarang!
			elif child.is_in_group("NaturalSpawner"):
				spawn_natural_monster(child.global_position, node)
		
		# Jika ada anak di dalam anak, ubek-ubek lagi ke struktur terdalam
		if child.get_child_count() > 0:
			_sortir_spawner_pakai_group(child)

# Fungsi khusus melahirkan monster natural langsung menempel di bawah ruangan pembawanya
func spawn_natural_monster(spawn_pos: Vector3, room_parent: Node3D):
	if natural_enemy_scene == null:
		print("PERINGATAN DETEKSI: Titik ketemu, tapi slot 'Natural Enemy Scene' di Inspector KOSONG!")
		return
		
	if is_instance_valid(room_parent):
		var natural_enemy = natural_enemy_scene.instantiate()
		
		# Jadikan anak dari ruangan itu sendiri agar ikut terhapus saat ganti level (bebas sampah memori)
		room_parent.add_child(natural_enemy)
		
		# Setel posisi GLOBAL-nya tepat di titik koordinat spawner
		natural_enemy.global_position = spawn_pos
		print("NATURAL SPAWN: Monster penjaga berhasil ditaruh di: ", spawn_pos, " di dalam ", room_parent.name)
