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
	# 👇 PENGAMAN: Jika belum masuk Scene Tree, jangan panggil get_tree().process_frame dulu
	if not is_inside_tree():
		return # Atau bisa diganti dengan: await tree_entered
		
	# Amankan antrean frame agar node layout siap di memori
	await get_tree().process_frame
	
	# 1. Update Teks Level secara instan
	if level_label:
		level_label.text = "LEVEL " + str(GameManager.current_level)
	
	# 2. Logika Indikator Kesulitan (1 Api tiap 5 Level, Max 5 Api)
	if fire_container:
		fire_container.visible = true
		
		# Menggunakan pembagian float agar pembulatan ceil() berjalan akurat di Godot 4
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
