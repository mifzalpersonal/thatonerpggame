# ==============================================================================
# item_slot.gd (Full Code - Transisi Murni Mengikuti Slot Angka 1 & 2)
# ==============================================================================
extends Control

@onready var weapon_sprite = $AnimatedSprite2D

func _ready() -> void:
	# Masukkan ke dalam grup agar bisa ditembak langsung oleh WeaponManager.gd
	add_to_group("HUD_Slot")
	
	if weapon_sprite:
		weapon_sprite.stop()
		weapon_sprite.frame = 0

## Fungsi utama memutar animasi transisi swap (Dipanggil oleh WeaponManager / Player)
func mainkan_animasi_tukar() -> void:
	if weapon_sprite:
		weapon_sprite.frame = 0 # Reset frame ke awal sebelum transisi dimulai
		weapon_sprite.play()    # Jalankan animasi (Pastikan opsi 'Loop' mati di sprite settings SpriteFrames)
		
	# --- OPTIONAL: UPDATE IKON VISUAL BERDASARKAN SENJATA AKTIF ---
	# Jika AnimatedSprite2D kamu memiliki nama animasi yang sama dengan nama senjata 
	# (Contoh nama animasi: "sword_slim", "katana", ""), kamu bisa aktifkan kode di bawah ini:
	
	# var player = get_tree().get_first_node_in_group("Player")
	# if player and player.has_node("Tangan"):
	# 	var manager_senjata = player.get_node("Tangan")
	# 	var nama_senjata = manager_senjata.slot_senjata[manager_senjata.slot_aktif]
	#
	# 	if nama_senjata == "":
	# 		weapon_sprite.animation = "default" # Pasang animasi tangan kosong / default
	# 	elif weapon_sprite.sprite_frames.has_animation(nama_senjata):
	# 		weapon_sprite.animation = nama_senjata
