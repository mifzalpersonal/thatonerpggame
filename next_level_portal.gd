extends Area3D

@export var enemy_scene: PackedScene
@export var spawn_points: Array = [] # Dibuat generik dan kosong agar diisi otomatis oleh Generator

@onready var ui_layer = $CanvasLayer
@onready var ui_label = $CanvasLayer/Panel/ConfirmLabel

# Status Portal: START_WAVE (awal), FIGHTING (lagi tanding), NEXT_LEVEL (selesai wave)
enum PortalState { START_WAVE, FIGHTING, NEXT_LEVEL }
var current_state = PortalState.START_WAVE

var enemies_alive: int = 0
var is_player_inside: bool = false

func _ready():
	ui_layer.visible = false
	
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
		start_wave()
	elif current_state == PortalState.NEXT_LEVEL:
		GameManager.go_to_next_level()

func _on_no_pressed():
	ui_layer.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# ==================== LOGIKA WAVE MUSUH ====================

func start_wave():
	print("Memulai Wave: ", GameManager.current_wave)
	var total_enemies = GameManager.current_wave * 3
	
	for i in range(total_enemies):
		await get_tree().create_timer(0.5).timeout # Jeda spawn antar monster wave
		spawn_enemy()

func spawn_enemy():
	# Pengaman jika portal ini adalah sisa level lalu yang sedang mengantre queue_free
	if not is_inside_tree():
		return
		
	if spawn_points.is_empty(): 
		print("Peringatan: Belum ada Spawn Points untuk Wave!")
		return
		
	# Menyaring instansi node EnemySpawnWav yang benar-benar aktif di Tree level baru
	var valid_wave_points: Array = []
	for point in spawn_points:
		if is_instance_valid(point):
			valid_wave_points.append(point)
			
	# Pengaman jika seluruh spawner terdeteksi mati/kosong
	if valid_wave_points.is_empty():
		print("Peringatan Fatal: Spawner yang diterima portal kondisinya tidak valid di memori!")
		return
		
	# Ambil acak salah satu node EnemySpawnWav
	var random_point = valid_wave_points.pick_random()
	
	# Lahirkan monster wave baru
	var wave_enemy = enemy_scene.instantiate()
	get_tree().current_scene.add_child(wave_enemy)
	
	# Proteksi posisi fisik: Ambil global_position langsung dari node spawner yang valid
	if "global_position" in random_point:
		wave_enemy.global_position = random_point.global_position
	else:
		wave_enemy.global_position = Vector3.ZERO
	
	# Sambungkan sinyal kematian musuh
	wave_enemy.tree_exited.connect(_on_enemy_defeated)
	enemies_alive += 1
	print("WAVE SPAWN: Monster lahir di posisi spawner: ", wave_enemy.global_position)

func _on_enemy_defeated():
	enemies_alive -= 1
	if enemies_alive <= 0:
		if GameManager.current_wave < GameManager.MAX_WAVES:
			GameManager.current_wave += 1
			await Engine.get_main_loop().create_timer(2.0).timeout
			start_wave()
		else:
			print("Pertempuran selesai! Kembalilah ke Portal untuk naik level.")
			current_state = PortalState.NEXT_LEVEL
			
			if is_player_inside:
				setup_ui_text()
