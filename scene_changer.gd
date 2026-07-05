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
	
	# 2. Mulai proses Loading Scene di Background
	ResourceLoader.load_threaded_request(target_scene_path)
	
	var load_status = ResourceLoader.THREAD_LOAD_IN_PROGRESS
	var progress = []
	
	while load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		load_status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
		await get_tree().process_frame # Tunggu frame berikutnya
	
	# 3. Logika Penahan Waktu (Agar tidak kecepatan)
	var minimum_loading_time = 10000 
	var time_passed = Time.get_ticks_msec() - start_time
	
	if time_passed < minimum_loading_time:
		# Jika loading aslinya terlalu cepat, tahan sisa waktunya di sini
		await get_tree().create_timer((minimum_loading_time - time_passed) / 1000.0).timeout
	
	# 4. Ganti Scene jika berhasil ter-load
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene = ResourceLoader.load_threaded_get(target_scene_path)
		get_tree().change_scene_to_packed(new_scene)
	else:
		print("Gagal meload scene, cek kembali path-nya!")
	
	# Matikan animasi spritesheet
	loading_sprite.stop()
	
	# TUNGGU 1 FRAME setelah scene ganti agar node-node di scene baru selesai dirakit oleh Godot
	await get_tree().process_frame
	
# 5. Jalankan animasi Fade From Black (Layar kembali terang)
	animation_player.play("fade_from_black")
	await animation_player.animation_finished
	
	# 6. CARA PINTAR: Cari karakter dengan memeriksa script-nya, bukan cuma namanya
	var player = _cari_karakter_player(get_tree().current_scene)
	
	if player:
		player.set_physics_process(true)
		print("SceneChanger: Berhasil mencairkan kebekuan karakter: ", player.name)
	else:
		# Jika tetap tidak ketemu, kita cetak daftar node yang ada di scene baru buat debug
		print("SceneChanger: Waduh, karakter gak ketemu di scene ini! Periksa nama nodemu.")
	
	control_ui.visible = false

# Fungsi pembantu untuk mencari node yang punya fungsi gerakan, apa pun namanya
func _cari_karakter_player(node: Node) -> Node:
	# Cek apakah node ini punya fungsi khas milik karaktermu
	if node.has_method("switch_hud_slot") or node.name == "Char3":
		return node
	
	# Jika bukan, cek anak-anak nodenya secara mendalam (rekursif)
	for child in node.get_children():
		var hasil = _cari_karakter_player(child)
		if hasil:
			return hasil
	return null
