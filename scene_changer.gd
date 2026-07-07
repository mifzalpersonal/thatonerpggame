extends CanvasLayer

@onready var animation_player = $AnimationPlayer
@onready var control_ui = $Control
@onready var loading_sprite = $Control/AnimatedSprite2D

func _ready():
	control_ui.visible = false
	loading_sprite.stop()

func change_scene_to(target_scene_path: String):
	control_ui.visible = true
	
	# 1. Jalankan animasi Fade To Black
	animation_player.play("fade_to_black")
	await animation_player.animation_finished
	
	# Mulai putar animasi spritesheet di kanan bawah
	loading_sprite.play("Loading")
	
	# Catat waktu awal saat loading dimulai
	var start_time = Time.get_ticks_msec()
	
	# 2. LOGIKA PERCEPATAN UNTUK REGENERASI MAP
	# Jika kita mendeteksi perintah "REGENERATE_MAP", kita bypass ResourceLoader karena scene-nya sudah ada
	if target_scene_path == "REGENERATE_MAP" or target_scene_path == GameManager.generator_scene_path:
		if GameManager.main_scene != null:
			# Muat ulang blueprint generator secara langsung tanpa loading asinkronus background yang bikin bug
			var new_scene = load(GameManager.generator_scene_path)
			GameManager.main_scene.change_map(new_scene)
			
			# Beri waktu jeda agar engine merakit ruangan LEGO-nya sampai tuntas
			await get_tree().process_frame
			await Engine.get_main_loop().create_timer(0.2).timeout
	else:
		# LOGIKA ASLI KAMU (Gunakan ResourceLoader hanya untuk pindah scene besar seperti dari Main Menu ke Game)
		ResourceLoader.load_threaded_request(target_scene_path)
		
		var load_status = ResourceLoader.THREAD_LOAD_IN_PROGRESS
		var progress = []
		
		while load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			load_status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
			await get_tree().process_frame # Tunggu frame berikutnya
		
		# 4. Ganti Scene jika berhasil ter-load
		if load_status == ResourceLoader.THREAD_LOAD_LOADED:
			var new_scene = ResourceLoader.load_threaded_get(target_scene_path)
			get_tree().change_scene_to_packed(new_scene)
		else:
			print("Gagal meload scene, cek kembali path-nya!")
	
	# 3. Logika Penahan Waktu (Agar tidak kecepatan)
	var minimum_loading_time = 3000 # Saya turunkan ke 3 detik agar player tidak bosan menunggu
	var time_passed = Time.get_ticks_msec() - start_time
	
	if time_passed < minimum_loading_time:
		# Menggunakan Engine global timer yang jauh lebih aman dari error null instance saat scene berganti
		await Engine.get_main_loop().create_timer((minimum_loading_time - time_passed) / 1000.0).timeout
	
	# Matikan animasi spritesheet
	loading_sprite.stop()
	
	# TUNGGU 1 FRAME setelah scene ganti agar node-node di scene baru selesai dirakit oleh Godot
	await get_tree().process_frame
	
	# 5. Jalankan animasi Fade From Black (Layar kembali terang)
	animation_player.play("fade_from_black")
	await animation_player.animation_finished
	
	# 6. CARA PINTAR: Cari karakter dengan memeriksa script-nya, bukan cuma namanya
	# Kita cari di Main Scene dulu karena Char3 sekarang menetap di sana secara permanen
	var player = null
	if GameManager.main_scene != null:
		player = _cari_karakter_player(GameManager.main_scene)
	else:
		player = _cari_karakter_player(get_tree().current_scene)
	
	if player:
		# SINKRONISASI POSISI AKHIR: Paksa kunci posisi player tepat di koordinat spawn baru sebelum melepas kontrol physics!
		player.set_physics_process(false)
		if "velocity" in player:
			player.velocity = Vector3.ZERO
		player.global_position = GameManager.player_spawn_position
		
		# Nyalakan kembali physics setelah posisinya dijamin akurat 100%
		player.set_physics_process(true)
		print("SceneChanger: Berhasil mencairkan kebekuan karakter dan mengunci posisi di: ", player.global_position)
	else:
		print("SceneChanger: Waduh, karakter gak ketemu di scene ini! Periksa nama nodemu.")
	
	control_ui.visible = false

# Fungsi pembantu untuk mencari node yang punya fungsi gerakan, apa pun namanya
func _cari_karakter_player(node: Node) -> Node:
	if node.has_method("switch_hud_slot") or node.name == "Char3":
		return node
	
	for child in node.get_children():
		var hasil = _cari_karakter_player(child)
		if hasil:
			return hasil
	return null
