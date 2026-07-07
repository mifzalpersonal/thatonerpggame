extends Node3D

@onready var level_container = $LevelContainer
@onready var player = $Char3

func _ready():
	# Serah terima jabatan: Daftarkan scene Main ini ke GameManager
	GameManager.main_scene = self
	
	# Dengarkan sinyal jika generator selesai menyusun ruangan
	GameManager.map_generation_complete.connect(_on_map_ready)
	
	# Mulai load level pertama
	GameManager.load_initial_level()

# Fungsi pembongkar-pasang map di dalam wadah
func change_map(new_map_scene: PackedScene):
	# 1. Bersihkan map lama agar memori RAM bersih dan tidak tumpuk
	for child in level_container.get_children():
		child.queue_free()
	
	# 2. Wujudkan blueprint map menjadi objek nyata di memori
	var map_instance = new_map_scene.instantiate()
	
	# 3. Masukkan objek map nyata tersebut ke dalam wadah (LevelContainer)
	level_container.add_child(map_instance)

# Berjalan otomatis setelah map selesai di-generate dan posisi fisik siap
func _on_map_ready():
	if player:
		# 1. Matikan proses physics player sementara (Biar dia gak ngelawan pas dipindah)
		player.set_physics_process(false)
		
		# 2. Reset total kecepatannya
		if "velocity" in player:
			player.velocity = Vector3.ZERO
		
		# 3. Pindahkan secara paksa ke koordinat SpawnPoint baru
		player.global_position = GameManager.player_spawn_position
		
		# 4. Paksa transformasi fisiknya diperbarui detik ini juga
		player.global_transform.origin = GameManager.player_spawn_position
		
		# 5. Hidupkan kembali physics player setelah posisinya aman
		player.set_physics_process(true)
		
	print("SISTEM: Player sukses dikunci di posisi Spawn baru: ", player.global_position)
