extends Node3D

@onready var config_ui = $CanvasLayer/ConfigUI
@onready var ui_animation = $CanvasLayer/UIAnimation
@onready var interaction_area = $InteractionArea # Mengambil node area langsung

var ui_is_open = false

func _ready():
	# Memaksa posisi UI berada di kondisi animasi tertutup saat awal masuk game
	if ui_animation.has_animation("close_ui"):
		ui_animation.play("close_ui")
		ui_animation.advance(1.0) 
	else:
		print("Peringatan: Animasi 'close_ui' tidak ditemukan di AnimationPlayer!")

func _process(delta):
	# Jika UI sudah disuruh menutup karena tombol Play dipencet, hentikan pengecekan area
	if not is_processing(): 
		return
		
	# Ambil semua objek fisik yang sedang berada di dalam area
	var bodies = interaction_area.get_overlapping_bodies()
	
	var char_di_dalam = false
	for body in bodies:
		if body.name == "Char3":
			char_di_dalam = true
			break
			
	# Jika Char3 masuk dan UI belum terbuka
	if char_di_dalam and not ui_is_open:
		ui_is_open = true
		ui_animation.play("open_ui")
		print("Sistem Paksa: Char3 masuk area!")
		
	# Jika Char3 keluar dan UI masih terbuka
	elif not char_di_dalam and ui_is_open:
		ui_is_open = false
		ui_animation.play("close_ui")
		print("Sistem Paksa: Char3 keluar area!")

# HUBUNGKAN KE SIGNAL: pressed milik CloseButton kamu
func _on_close_button_pressed():
	ui_is_open = false
	ui_animation.play("close_ui")

# HUBUNGKAN KE SIGNAL: pressed milik PlayButton kamu (Tombol Let's Go)
func _on_play_button_pressed():
	# 1. MATIKAN FUNGSI PROCESS LOBBY agar area tidak mengecek tabrakan lagi
	set_process(false)
	
	# 2. CARI SI CHAR3 DI LOBBY DAN LANGSUNG BEKUKAN DI TEMPAT!
	var player = find_child("Char3", true, false)
	if player:
		player.set_physics_process(false)
		print("Lobby: Char3 dikunci! Gak bisa jalan-jalan pas loading.")

	# 3. Sembunyikan UI interaksi dengan animasi bergeser keluar dulu
	ui_is_open = false
	ui_animation.play("close_ui")
	await ui_animation.animation_finished
	
	# 4. Panggil loading screen autoload untuk pindah ke map utama game
	SceneChanger.change_scene_to("res://Map-Asset/Scene/Main.tscn")
