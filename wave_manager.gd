extends Node3D

@export var enemy_scene: PackedScene
@export var next_level_portal: Area3D # Nanti di-klik & sambungkan ke portal lewat Inspector

var spawn_points: Array[Node3D] = []
var enemies_alive: int = 0

func _ready():
	# Ambil semua anak node sebagai titik spawn otomatis
	for child in get_children():
		if child is Node3D:
			spawn_points.append(child)
			
	# Matikan portal dulu sebelum semua wave bersih
	if next_level_portal:
		next_level_portal.visible = false
		next_level_portal.set_deferred("monitoring", false)
		
func start_wave():
	print("Memulai Wave: ", GameManager.current_wave)
	# Jumlah musuh: Wave 1 = 3, Wave 2 = 6, Wave 3 = 9 musuh
	var total_enemies = GameManager.current_wave * 3 
	
	for i in range(total_enemies):
		await get_tree().create_timer(1.0).timeout # Jeda 1 detik tiap spawn musuh
		spawn_enemy()

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	var random_point = spawn_points.pick_random()
	enemy.global_position = random_point.global_position
	
	# Saat musuh mati (keluar dari tree), jalankan pengecekan wave
	enemy.tree_exited.connect(_on_enemy_defeated)
	get_parent().add_child(enemy)
	enemies_alive += 1

func _on_enemy_defeated():
	# 👇 PENGAMAN 1: Jika node ini sudah keluar dari game tree (sedang loading/pindah scene), STOP!
	if not is_inside_tree():
		return

	# 👇 PENGAMAN 2: Jika level kembali ke 1 (habis reset_game), jangan proses sisa musuh lama!
	if GameManager.current_level == 1:
		return

	enemies_alive -= 1
	if enemies_alive <= 0:
		if GameManager.current_wave < GameManager.MAX_WAVES:
			GameManager.current_wave += 1
			await get_tree().create_timer(3.0).timeout 
			
			# 👇 PENGAMAN 3: Cek lagi sebelum wave baru benar-benar dimulai
			if is_inside_tree() and GameManager.current_level > 1:
				start_wave()
		else:
			print("Semua Wave Selesai! Portal Terbuka.")
			if next_level_portal:
				next_level_portal.visible = true
				next_level_portal.set_deferred("monitoring", true)
