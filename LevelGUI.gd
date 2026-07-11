extends Control

@onready var level_label = $LevelContainer/LevelLabel
@onready var fire_container = $LevelContainer/FireContainer

func _ready():
	# Hubungkan ke GameManager agar tahu kapan level berubah
	if GameManager.has_signal("level_changed"):
		GameManager.level_changed.connect(_on_level_changed)
	
	# Jalankan setup pertama kali saat game dibuka
	perbarui_tampilan_level()

func _on_level_changed():
	perbarui_tampilan_level()

func perbarui_tampilan_level():
	# Amankan antrean frame agar node layout siap di memori
	await get_tree().process_frame
	
	# 1. Update Teks Level secara instan
	if level_label:
		level_label.text = "LEVEL " + str(GameManager.current_level)
	
	# 2. Logika Indikator Kesulitan (1 Api tiap 5 Level, Max 5 Api)
	if fire_container:
		# Pastikan container utama apinya sendiri hidup/visible terlebih dahulu!
		fire_container.visible = true
		
		var jumlah_api = clampi(ceil(GameManager.current_level / 5.0), 1, 5)
		var daftar_slot = fire_container.get_children()
		
		for i in range(daftar_slot.size()):
			if i < jumlah_api:
				# Hidupkan slot container apinya
				daftar_slot[i].visible = true
				
				# Paksa node di dalamnya (AnimatedSprite2D/Sprite2D) untuk kelihatan dan berputar
				if daftar_slot[i].get_child_count() > 0:
					var sprite_api = daftar_slot[i].get_child(0) 
					if sprite_api:
						# Pastikan sprite individunya tidak tersembunyi
						if "visible" in sprite_api:
							sprite_api.visible = true
						# Putar animasi apinya secara paksa lewat kode
						if sprite_api.has_method("play"):
							sprite_api.play("default")
			else:
				# Sembunyikan slot api yang belum waktunya muncul
				daftar_slot[i].visible = false
				
		print("GUI STATUS: Tampilan Level ", GameManager.current_level, " & ", jumlah_api, " Api Berhasil Muncul!")
