extends RigidBody3D

@export var nama_senjata : String = "Sabit Biru"

var player_di_area : CharacterBody3D = null
var waktu_tunggu : float = 0.0
var sudah_ditukar : bool = false

func _ready() -> void:
	$AmbilArea.body_entered.connect(_on_body_entered)
	$AmbilArea.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		if body.has_node("Tangan"):
			var tangan = body.get_node("Tangan")
			if tangan.has_method("ambil_senjata"):
				var slot_cadangan = 1 if tangan.slot_aktif == 0 else 0
				
				# KONDISI 1: Jika masih ada slot kosong (langsung ambil tanpa nunggu)
				if tangan.slot_senjata[tangan.slot_aktif] == "" or tangan.slot_senjata[slot_cadangan] == "":
					tangan.ambil_senjata(nama_senjata)
					queue_free()
				# KONDISI 2: Jika penuh, catat player-nya buat mulai hitung mundur 2 detik
				else:
					player_di_area = body
					waktu_tunggu = 0.0
					print("Inventori penuh! Berdirilah di sini selama 2 detik untuk menukar senjata.")

func _on_body_exited(body: Node3D) -> void:
	if body == player_di_area:
		player_di_area = null
		waktu_tunggu = 0.0
		print("Batal menukar senjata karena lu pergi.")

func _process(delta: float) -> void:
	# Jika ada player di dalam area dan inventori penuh
	if player_di_area != null and not sudah_ditukar:
		waktu_tunggu += delta
		
		# Jika sudah berdiri selama 2 detik
		if waktu_tunggu >= 2.0:
			sudah_ditukar = true
			eksekusi_tukar_senjata()

func eksekusi_tukar_senjata() -> void:
	if player_di_area == null:
		return
		
	var tangan = player_di_area.get_node("Tangan")
	
	# 1. Ambil nama senjata lama yang lagi dipegang player saat ini
	var senjata_lama = tangan.slot_senjata[tangan.slot_aktif]
	
	# 2. Paksa tangan player buat ngambil senjata baru ini
	tangan.slot_senjata[tangan.slot_aktif] = nama_senjata
	tangan.pasang_visual_senjata(nama_senjata)
	print("Berhasil tukar! Sekarang megang: ", nama_senjata)
	
	# 3. Ubah identitas barang di tanah ini jadi nama senjata lama milik player tadi
	nama_senjata = senjata_lama
	sudah_ditukar = false
	waktu_tunggu = 0.0
	
	# Beri sedikit efek dorongan ke atas biar barang yang baru dibuang kelihatan memantul gantiin posisi
	apply_central_impulse(Vector3(0, 3.0, 0))
