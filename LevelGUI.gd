extends Control

@onready var level_label = $LevelContainer/LevelLabel
@onready var fire_container = $LevelContainer/FireContainer

# Gunakan active tween untuk menghindari bug penumpukan timer jika sinyal terpanggil ganda
var active_tween: Tween

func _ready():
	# Hubungkan ke GameManager agar tahu kapan level berubah
	if GameManager.has_signal("level_changed"):
		GameManager.level_changed.connect(_on_level_changed)
	
	# Sembunyikan secara default saat awal game/pindah map dimulai
	# UI hanya akan muncul jika dipicu oleh sinyal level_changed
	visible = false
	perbarui_tampilan_level()
	
	# Jalankan durasi 5 detik untuk level pertama saat game baru dibuka
	munculkan_sementara(5.0)

func _on_level_changed():
	perbarui_tampilan_level()
	# Setiap kali sinyal level_changed masuk (baik wave terakhir selesai atau pindah level), munculkan selama 5 detik
	munculkan_sementara(5.0)

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
# ⏱️ FUNGSI DURASI WAKTU TAMPIL (DENGAN TWEEN AGAR LEBIH AMAN DARI RE-LOAD)
# ==============================================================================
func munculkan_sementara(durasi: float) -> void:
	# Jika ada timer/tween berjalan sebelumnya, matikan dulu agar tidak bentrok
	if active_tween:
		active_tween.kill()
		
	# 1. Buat UI menjadi terlihat
	visible = true
	
	# 2. Gunakan Tween SceneTree sebagai pengganti create_timer agar tidak memicu memory leak saat ganti scene
	active_tween = create_tween()
	active_tween.tween_callback(func(): visible = false).set_delay(durasi)
	
	print("GUI STATUS: Level GUI ditampilkan selama ", durasi, " detik.")
