extends Marker3D

var slot_senjata = ["", ""]
var slot_aktif = 0
var node_senjata_di_tangan : Node = null

var senjata_sekarang : String:
	get:
		return slot_senjata[slot_aktif]

func ambil_senjata(nama_barang: String) -> void:
	if slot_senjata[slot_aktif] == "":
		slot_senjata[slot_aktif] = nama_barang
		print("Slot ", slot_aktif + 1, " diisi: ", nama_barang)
		pasang_visual_senjata(nama_barang)
		print("bang lu nemu ", nama_barang)
		return
		
	var slot_cadangan = 1 if slot_aktif == 0 else 0
	
	if slot_senjata[slot_cadangan] == "":
		slot_senjata[slot_cadangan] = nama_barang
		print("Slot aktif penuh, dimasukkan ke Slot ", slot_cadangan + 1, ": ", nama_barang)
		return

func ganti_slot(nomor_slot: int) -> void:
	var indeks_baru = nomor_slot - 1
	if indeks_baru == slot_aktif:
		return
		
	slot_aktif = indeks_baru
	print("Swapped ke Slot: ", nomor_slot)
	pasang_visual_senjata(slot_senjata[slot_aktif])

func pasang_visual_senjata(nama_barang: String) -> void:
	if node_senjata_di_tangan != null:
		node_senjata_di_tangan.queue_free()
		node_senjata_di_tangan = null
		
	if nama_barang == "":
		return
		
	var path_senjata = "res://" + nama_barang + ".tscn"
	
	if ResourceLoader.exists(path_senjata):
		var blueprint = load(path_senjata)
		var model_baru = blueprint.instantiate()
		add_child(model_baru)
		node_senjata_di_tangan = model_baru
	else:
		print("Eror: File senjata ", path_senjata, " gak ketemu!")
		
	# ========================================================
	# --- TWEAK BARU PASIF SPEED KATANA (TARUH DI PALING BAWAH FUNGSI) ---
	# ========================================================
	# Ambil acuan ke player (induk dari weapon manager ini)
	var player = get_parent()
	if player and "speed" in player:
		# Kembalikan ke kecepatan normal default lu dulu tiap ganti senjata
		player.speed = 10.0 # <--- Set sesuai angka speed default di script walk lu
		
		# Jika beralih memegang katana, dongkrak speed-nya 30%
		if nama_barang.contains("katana") or nama_barang.contains("Katana"):
			if player.has_method("apply_speed_boost"):
				# Multiplier: 1.3 (+30%), Durasi: 99999.0 (Biar permanen pas dipegang)
				player.apply_speed_boost(2.0, 99999.0)
				print("🩸 PASIF KATANA: Memanggil apply_speed_boost permanen!")
		else:
			# Jika ganti ke senjata lain, matikan pasif katananya pake fungsi timeout bawaan!
			if "speed_boost_timer" in player and not player.speed_boost_timer.is_stopped():
				player.speed_boost_timer.stop() # Stop timernya biar gak bocor
			
			if player.has_method("_on_speed_boost_timeout"):
				player._on_speed_boost_timeout() # Panggil fungsi reset murni buatan temen lu!
				print("🔄 SENJATA DIGANTI: Eksekusi timeout untuk reset speed.")
	# ========================================================

func eksekusi_menyerang() -> void:
	if slot_senjata[slot_aktif] != "":
		print("Menyerang pake: ", slot_senjata[slot_aktif])
