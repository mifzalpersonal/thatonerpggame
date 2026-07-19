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

func start_wave():
	# 👍 PENGAMAN DISESUAIKAN: Hanya stop jika portal keluar dari tree
	if not is_inside_tree():
		return
		
	print("Memulai Wave: ", GameManager.current_wave)
	var total_enemies = GameManager.current_wave * 3
	
	for i in range(total_enemies):
		if not is_inside_tree():
			return
		await get_tree().create_timer(0.5).timeout 
		spawn_enemy()

func spawn_enemy():
	if not is_inside_tree():
		return
		
	if spawn_points.is_empty(): 
		print("Peringatan: Belum ada Spawn Points untuk Wave!")
		return
		
	var valid_wave_points: Array = []
	for point in spawn_points:
		if is_instance_valid(point):
			valid_wave_points.append(point)
			
	if valid_wave_points.is_empty():
		print("Peringatan Fatal: Spawner tidak valid di memori!")
		return
		
	var random_point = valid_wave_points.pick_random()
	
	var wave_enemy = enemy_scene.instantiate()
	get_tree().current_scene.add_child(wave_enemy)
	
	if "global_position" in random_point:
		wave_enemy.global_position = random_point.global_position
	else:
		wave_enemy.global_position = Vector3.ZERO
	
	wave_enemy.tree_exited.connect(_on_enemy_defeated)
	enemies_alive += 1
	print("WAVE SPAWN: Monster lahir di posisi: ", wave_enemy.global_position)

func _on_enemy_defeated():
	# 🔴 PENGAMAN UTAMA: Kita pakai variabel enemies_alive sebagai tameng. 
	# Jika musuh berkurang saat portal sudah mau dihancurkan (pindah scene/exit), 
	# abaikan saja kodenya agar tidak menaikkan wave secara tidak sengaja.
	if not is_inside_tree():
		return

	enemies_alive -= 1
	
	# Jika kematian musuh dipicu karena pindah scene/loading, enemies_alive bisa minus banyak.
	# Kita hanya naikkan wave kalau permainannya memang sedang berjalan normal.
	if enemies_alive <= 0:
		# Cek tambahan: jika angka minus (artinya dihapus paksa oleh engine saat ganti scene), abaikan!
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
