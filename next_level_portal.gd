extends Area3D

@export var enemy_scene: PackedScene
@export var spawn_points: Array # DIUBAH JADI GENERIK AGAR TIDAK ERROR NATIVE TYPE 'Node3D'

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
	if spawn_points.is_empty(): 
		print("Peringatan: Belum ada Spawn Points untuk Wave!")
		return
		
	# 1. Saring ulang kandidat spawner yang murni masuk ke dalam group WaveSpawner
	var valid_wave_points: Array = []
	for point in spawn_points:
		if is_instance_valid(point) and point.is_in_group("WaveSpawner"):
			valid_wave_points.append(point)
			
	# 2. Pengaman darurat jika data kosong
	if valid_wave_points.is_empty():
		print("Peringatan Fatal: Tidak ada node dengan group 'WaveSpawner' yang diterima portal!")
		return
		
	# 3. Ambil acak murni dari daftar wave yang bersih dari intervensi spawner natural
	var random_point = valid_wave_points.pick_random()
	
	var wave_enemy = enemy_scene.instantiate()
	
	# Masukkan ke Main Scene dunia luar, baru setel global_position-nya
	get_tree().current_scene.add_child(wave_enemy)
	wave_enemy.global_position = random_point.global_position
	
	# Sambungkan sinyal kematian monster wave untuk menghitung sisa musuh
	wave_enemy.tree_exited.connect(_on_enemy_defeated)
	enemies_alive += 1
	print("WAVE SPAWN: Monster tantangan murni lahir di spawner wave: ", wave_enemy.global_position)

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
