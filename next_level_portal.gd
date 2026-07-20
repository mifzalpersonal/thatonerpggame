extends Area3D

# 🔥 REVISI SLOT: Mengganti slot tunggal dengan slot acak kroco dan satu slot boss
@export var wave_enemy_1: PackedScene # Slot untuk Kroco 1 (e.g. enemy1.tscn)
@export var wave_enemy_2: PackedScene # Slot untuk Kroco 2 (e.g. enemy2.tscn)
@export var boss_scene: PackedScene   # Slot untuk BOSS.tscn
@export var spawn_points: Array = [] # Diisi otomatis secara sakti oleh Generator

@onready var ui_layer = $CanvasLayer
@onready var ui_label = $CanvasLayer/Panel/ConfirmLabel

# Status Portal: START_WAVE (awal), FIGHTING (lagi tanding), NEXT_LEVEL (selesai wave)
enum PortalState { START_WAVE, FIGHTING, NEXT_LEVEL }
var current_state = PortalState.START_WAVE

var enemies_alive: int = 0
var is_player_inside: bool = false

func _ready():
	ui_layer.visible = false
	current_state = PortalState.START_WAVE # Pengaman: Selalu reset status ke awal saat scene di-load
	enemies_alive = 0                      # Pengaman: Bersihkan hitungan sisa musuh lama
	
	# Hubungkan signal bawaan Area3D
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Hubungkan tombol UI
	$CanvasLayer/Panel/IysButton.pressed.connect(_on_yes_pressed)
	$CanvasLayer/Panel/TdkButton.pressed.connect(_on_no_pressed)

func _on_body_entered(body):
	if body.name == "Char3" or body.is_in_group("Player"):
		is_player_inside = true
		setup_ui_text()

func _on_body_exited(body):
	if body.name == "Char3" or body.is_in_group("Player"): 
		is_player_inside = false
		ui_layer.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Fungsi untuk mengubah teks UI sesuai status portal saat ini
func setup_ui_text():
	if current_state == PortalState.START_WAVE:
		ui_label.text = "Mulai Pertempuran (Wave 1-3)?"
		ui_layer.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif current_state == PortalState.NEXT_LEVEL:
		ui_label.text = "Semua musuh kalah! Lanjut ke Level Selanjutnya?"
		ui_layer.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif current_state == PortalState.FIGHTING:
		ui_layer.visible = false

func _on_yes_pressed():
	ui_layer.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if current_state == PortalState.START_WAVE:
		current_state = PortalState.FIGHTING
		
		# MUNCULKAN UI WAVE SAAT TOMBOL YES DIKLIK (FIGHTING DIMULAI)
		get_tree().call_group("UI_Wave", "set_visible", true)
		get_tree().call_group("UI_Wave", "update_wave_ui")
		
		start_wave()
	elif current_state == PortalState.NEXT_LEVEL:
		GameManager.go_to_next_level()

func _on_no_pressed():
	ui_layer.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# ==================== LOGIKA WAVE MUSUH ====================

# ==================== LOGIKA WAVE MUSUH ====================

func start_wave():
	if not is_inside_tree():
		return
		
	print("Memulai Wave: ", GameManager.current_wave)
	
	# 🔥 FITUR LOKAL LU: TIAP 3 LEVEL, MAX WAVES DI ALTAR NAMBAH 1
	var tambahan_wave = int(GameManager.current_level / 3)
	GameManager.MAX_WAVES = 3 + tambahan_wave
	
	if spawn_points.is_empty(): 
		print("Peringatan: Belum ada Spawn Points untuk Wave!")
		return
		
	# 🔥 FITUR UTAMA: DI LEVEL 5 DAN WAVE TERAKHIR -> SPAWN BOSS UTAMA
	if GameManager.current_level == 1 and GameManager.current_wave == 1:
	#if GameManager.current_level == 5 and GameManager.current_wave == GameManager.MAX_WAVES:
		print("🚨 PERINGATAN: KONDISI BOSS TERPENUHI! SPAWNING THE BOSS!")
		spawn_boss()
		return # Berhenti di sini agar kroco biasa tidak keluar
	
	# 🔥 PERBAIKAN SAKTI: SPAWN KROCO PELAN-PELAN PAKE JEDA
	var total_enemies = GameManager.current_wave * 3
	for i in range(total_enemies):
		# Pengaman: Cek setiap iterasi kalau-kalau player mati/pindah scene pas lagi nunggu jeda
		if not is_inside_tree() or current_state != PortalState.FIGHTING:
			return
			
		spawn_enemy()
		
		# Kasih jeda 0.8 detik sebelum melahirkan kroco berikutnya biar gak numpuk dan mental
		await get_tree().create_timer(0.8).timeout
# REVISI SPAWN KROCO: Logika acak 50/50
func spawn_enemy():
	if not is_inside_tree():
		return
		
	if wave_enemy_1 == null or wave_enemy_2 == null:
		print("Peringatan: Slot wave enemy 1 atau 2 masih kosong!")
		return
		
	var valid_wave_points: Array = []
	for point in spawn_points:
		if is_instance_valid(point):
			valid_wave_points.append(point)
			
	if valid_wave_points.is_empty():
		return
		
	var random_point = valid_wave_points.pick_random()
	
	# Kocok probabilitas 50% / 50% untuk variasi musuh
	var terpilih_scene: PackedScene
	if randf() < 0.5:
		terpilih_scene = wave_enemy_1
	else:
		terpilih_scene = wave_enemy_2
		
	var wave_enemy = terpilih_scene.instantiate()
	get_tree().current_scene.add_child(wave_enemy)
	
	if "global_position" in random_point:
		wave_enemy.global_position = random_point.global_position
	else:
		wave_enemy.global_position = Vector3.ZERO
	
	wave_enemy.tree_exited.connect(_on_enemy_defeated)
	enemies_alive += 1
	print("WAVE SPAWN: Monster lahir di posisi: ", wave_enemy.global_position)

# 🔥 FUNGSI BARU: Khusus melahirkan Sang Boss Utama
func spawn_boss():
	if boss_scene == null:
		print("Error: Scene Boss belum di-drag ke slot Inspector Portal!")
		# Failsafe: spawn kroco biasa kalau lupa masukin boss
		var total_enemies = GameManager.current_wave * 3
		for i in range(total_enemies): spawn_enemy()
		return
		
	var valid_wave_points: Array = []
	for point in spawn_points:
		if is_instance_valid(point):
			valid_wave_points.append(point)
			
	if valid_wave_points.is_empty():
		return
		
	var random_point = valid_wave_points.pick_random()
	var boss = boss_scene.instantiate()
	
	get_tree().current_scene.add_child(boss)
	
	if "global_position" in random_point:
		boss.global_position = random_point.global_position
	else:
		boss.global_position = Vector3.ZERO
		
	boss.tree_exited.connect(_on_enemy_defeated)
	enemies_alive += 1
	print("🚨 BOSS SPAWN: Sang Boss Utama lahir di posisi: ", boss.global_position)

func _on_enemy_defeated():
	if not is_inside_tree():
		return

	enemies_alive -= 1
	
	if enemies_alive <= 0:
		if enemies_alive < 0:
			return
			
		if GameManager.current_wave < GameManager.MAX_WAVES:
			GameManager.current_wave += 1
			GameManager.level_changed.emit()
			
			if is_inside_tree():
				await get_tree().create_timer(2.0).timeout
				if is_inside_tree():
					start_wave()
		else:
			print("Pertempuran selesai! Kembalilah ke Portal untuk naik level.")
			current_state = PortalState.NEXT_LEVEL
			
			get_tree().call_group("UI_Wave", "set_visible", false)
			
			if is_player_inside:
				setup_ui_text()
