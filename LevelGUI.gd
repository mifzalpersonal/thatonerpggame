extends Control

@onready var level_label = $LevelContainer/LevelLabel
@onready var fire_container = $LevelContainer/FireContainer

# Variabel pembantu untuk mendeteksi apakah ini pertama kali game dijalankan
var game_baru_mulai: bool = true

func _ready():
	# Hubungkan ke GameManager agar tahu kapan level berubah (Scene Changer memicu ini)
	if GameManager.has_signal("level_changed"):
		GameManager.level_changed.connect(_on_level_changed)
	
	# Saat pertama kali game dibuka, biarkan UI terlihat permanen/normal
	perbarui_tampilan_level()

func _on_level_changed():
	perbarui_tampilan_level()
	
	# Jika level berubah karena scene changer, jalankan fungsi durasi 5 detik
	if not game_baru_mulai:
		munculkan_sementara(5.0)
	else:
		game_baru_mulai = false

func perbarui_tampilan_level():
	if not is_inside_tree():
		return
		
	await get_tree().process_frame
	
	# 1. Update Teks Level
	if level_label:
		level_label.text = "LEVEL " + str(GameManager.current_level)
	
	# 2. Logika Indikator Kesulitan Api
	if fire_container:
		fire_container.visible = true
		
		var jumlah_api = clampi(ceil(float(GameManager.current_level) / 5.0), 1, 5)
		var daftar_slot = fire_container.get_children()
		
		for i in range(daftar_slot.size()):
			if i < jumlah_api:
				daftar_slot[i].visible = true
				if daftar_slot[i].get_child_count() > 0:
					var sprite_api = daftar_slot[i].get_child(0) 
					if sprite_api:
						if "visible" in sprite_api:
							sprite_api.visible = true
						if sprite_api.has_method("play"):
							sprite_api.play("default")
			else:
				daftar_slot[i].visible = false
				
		print("GUI STATUS: Tampilan Level ", GameManager.current_level, " & ", jumlah_api, " Api Berhasil Muncul!")

# ==============================================================================
# ⏱️ FUNGSI DURASI WAKTU TAMPIL
# ==============================================================================
func munculkan_sementara(durasi: float) -> void:
	# 1. Buat UI menjadi terlihat
	visible = true
	
	# 2. Tunggu selama X detik (dalam kasus ini 5 detik)
	await get_tree().create_timer(durasi).timeout
	
	# 3. Sembunyikan UI setelah waktu habis
	visible = false
	print("GUI STATUS: Waktu habis, Level GUI disembunyikan.")
