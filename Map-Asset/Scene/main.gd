extends Node3D

@onready var level_container = $LevelContainer
@onready var player = $CharacterBody3D

func _ready():
	# Serah terima jabatan: Daftarkan scene Main ini ke GameManager
	GameManager.main_scene = self
	
	# Dengarkan sinyal jika generator selesai menyusun ruangan
	GameManager.map_generation_complete.connect(_on_map_ready)
	
	# Mulai load level pertama
	GameManager.load_initial_level()

func change_map(new_map_scene: PackedScene):
	# 1. Sebelum menghapus, putus hubungan sinyal agar tidak ada sinyal nyasar ke node lama
	if GameManager.map_generation_complete.is_connected(_on_map_ready):
		GameManager.map_generation_complete.disconnect(_on_map_ready)

	# 2. Bersihkan map lama dari wadah LevelContainer
	for child in level_container.get_children():
		child.queue_free()
	
	# 3. Tunggu 1 frame penuh agar objek lama BENAR-BENAR musnah dari memori dunia
	await get_tree().process_frame
	
	# 4. Hubungkan kembali sinyalnya khusus untuk map yang baru nanti
	GameManager.map_generation_complete.connect(_on_map_ready)
	
	# 5. Setelah dunia bersih total, barulah lahirkan map baru
	var map_instance = new_map_scene.instantiate()
	level_container.add_child(map_instance)
	print("MAIN_SCENE: Map lama musnah total, map baru dilahirkan dengan aman!")
	
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
