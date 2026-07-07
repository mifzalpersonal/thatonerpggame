extends Node

@export var max_hp: int = 5
@export var regen_cooldown: float = 10.0 # Waktu tunggu sebelum regen (10 detik)
@export var regen_speed: float = 1.0     # Jeda penambahan HP saat regen (tiap 1 detik)
@export var regen_amount: float = 1.0    # Jumlah HP yang bertambah setiap kali regen

# --- TAMBAHAN VARIABEL DEAD SCENE ---
@export var dead_scene: PackedScene 
var is_dead: bool = false
# ------------------------------------

var hp: float = 5.0 : set = set_hp 

@onready var game_ui = get_node_or_null("/root/Main/GUI/GameUI")

# Variabel internal untuk mengatur Timer lewat kode
var cooldown_timer: SceneTreeTimer
var is_regen_active: bool = false

func _ready() -> void:
	await get_tree().process_frame
	if game_ui != null:
		game_ui.setup_hearts(max_hp, hp)

func set_hp(value: float) -> void:
	if is_dead: return # Jika sudah mati, HP tidak bisa diotak-atik lagi
	
	var old_hp = hp
	hp = clamp(value, 0, max_hp)
	
	if game_ui != null:
		game_ui.update_hearts(hp)
		
	# LOGIKA DETEKSI DAMAGE:
	if hp < old_hp:
		print("Player kena damage! Reset waktu tunggu regen.")
		reset_regen_cooldown()
		
	# --- DETEKSI KEMATIAN PLAYER ---
	if hp <= 0 and not is_dead:
		pemicu_kematian()

func pemicu_kematian() -> void:
	is_dead = true
	is_regen_active = false
	print("Player kalah, memulai animasi kematian...")
	
	var player = get_parent()
	
	# 1. Matikan Hitbox Player
	var collision = player.get_node_or_null("CollisionShape3D")
	if collision:
		collision.set_deferred("disabled", true)
		
	# 2. AMBIL NODE ANIMATEDSPRITE3D & JALANKAN ANIMASI
	var sprite = player.get_node_or_null("AnimatedSprite3D") # sesuaikan kalau namanya beda
	if sprite and sprite.sprite_frames.has_animation("Die"):
		sprite.play("Die")
	elif sprite and sprite.sprite_frames.has_animation("Death"):
		sprite.play("Death")

	# 3. --- EFEK KAMERA DRAMATIS (ZOOM & SHAKE) ---
	var camera = get_tree().get_root().get_camera_3d() # Mengambil kamera yang sedang aktif
	if camera:
		var camera_tween = create_tween().set_parallel(true) # Set parallel agar zoom & shake jalan bareng
		
		# Efek A: Kamera mendekat (Zoom In) dengan cara mengecilkan FOV selama 0.5 detik
		# Nilai normal FOV biasanya 75, kita kecilkan ke 45 biar nge-zoom
		camera_tween.tween_property(camera, "fov", 45.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Efek B: Screen Shake (Goyang) sederhana menggunakan offset posisi x dan y kamera
		var posisi_awal_h = camera.h_offset
		var posisi_awal_v = camera.v_offset
		
		# Bikin goyangan cepat memakai rantai tween (chaining)
		var shake_tween = create_tween()
		for i in range(5): # Goyang 5 kali secara cepat
			shake_tween.tween_property(camera, "h_offset", posisi_awal_h + randf_range(-0.1, 0.1), 0.05)
			shake_tween.tween_property(camera, "v_offset", posisi_awal_v + randf_range(-0.1, 0.1), 0.05)
		# Kembalikan posisi kamera ke normal setelah goyang selesai
		shake_tween.tween_property(camera, "h_offset", posisi_awal_h, 0.05)
		shake_tween.tween_property(camera, "v_offset", posisi_awal_v, 0.05)

	# 4. TUNGGU ANIMASI SPRITE SELESAI (Misal durasi mati sprite-mu sekitar 1 detik)
	# Kamu bisa sesuaikan detiknya dengan panjang animasi sprite kamu
	await get_tree().create_timer(1.5).timeout
	
	# 5. PROSES SPAWN UI DEAD SCENE (Sama seperti kemarin yang sudah fix)
	if dead_scene:
		var layar_mati = dead_scene.instantiate()
		layar_mati.process_mode = Node.PROCESS_MODE_ALWAYS
		
		var canvas_gui = get_node_or_null("/root/Main/GUI")
		if canvas_gui != null:
			canvas_gui.add_child(layar_mati)
		else:
			get_tree().root.add_child(layar_mati)
		
		get_tree().paused = true
		
		await get_tree().process_frame
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		var tombol_lobby = layar_mati.get_node_or_null("MenuContainer/VBoxContainer/Lobby") 
		if tombol_lobby:
			tombol_lobby.grab_focus()

# Fungsi untuk mengulang kembali waktu tunggu 10 detik
func reset_regen_cooldown() -> void:
	if is_dead: return
	is_regen_active = false 
	
	cooldown_timer = get_tree().create_timer(regen_cooldown)
	await cooldown_timer.timeout
	
	if cooldown_timer != null and not is_regen_active and hp < max_hp and not is_dead:
		start_regeneration()

# Fungsi yang berjalan ketika player sukses "aman" selama 10 detik
func start_regeneration() -> void:
	is_regen_active = true
	print("Player aman! Mulai proses regenerasi HP...")
	
	while is_regen_active and hp < max_hp and not is_dead:
		self.hp += regen_amount
		print("Regen aktif! HP bertambah jadi: ", hp)
		await get_tree().create_timer(regen_speed).timeout
	
	if hp >= max_hp:
		is_regen_active = false
		print("HP sudah penuh, regenerasi selesai.")
