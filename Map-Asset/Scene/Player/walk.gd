extends CharacterBody3D

@export var speed := 20.0
@onready var anim = $AnimatedSprite3D

# Lu tinggal tambahin daftarnya ke bawah sampai 20 senjata, Twin!
const DAFTAR_SENJATA = {
	"Sabit Biru": preload("res://WeaponDrop.tscn"),
	}
const SABETAN_ENERGI_SCENE = preload("res://slash.tscn")

@onready var node_tangan = $Tangan
var senjata_sekarang : String = ""
var node_senjata_di_tangan : Node3D = null # Buat nginget objek senjata yang lagi dipegang

func _physics_process(delta):
	var input_dir = Vector3.ZERO

	# WASD input (Sudah diperbaiki arah Z nya)
	if Input.is_key_pressed(KEY_W):
		input_dir.z += 1 # -Z adalah ATAS/DEPAN
	if Input.is_key_pressed(KEY_S):
		input_dir.z -= 1 # +Z adalah BAWAH/BELAKANG
	if Input.is_key_pressed(KEY_A):
		input_dir.x += 1 # -X adalah KIRI
	if Input.is_key_pressed(KEY_D):
		input_dir.x -= 1 # +X adalah KANAN

	# Normalisasi biar jalan diagonal gak lebih cepat
	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()

	# Gerakan
	velocity = input_dir * speed
	move_and_slide()

	# Logika Animasi 4 Arah
	if input_dir == Vector3.ZERO:
		# Jika diam, mainkan animasi Idle (atau bisa pakai anim.stop())
		anim.play("Walk_Down") 
	else:
		# Utamakan animasi horizontal jika bergerak diagonal, atau sesuaikan seleramu
		if abs(input_dir.x) > abs(input_dir.z):
			if input_dir.x > 0:
				anim.play("Idle_Right")
			else:
				anim.play("Idle_Left")
		else:
			if input_dir.z > 0:
				anim.play("Idle_Up")
			else:
				anim.play("Walk_Down")

	# Catatan: Baris flip_h di bawah ini dihapus karena kamu sudah punya 
	# animasi "Walk_Left" dan "Walk_Right" terpisah di AnimatedSprite3D.
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):	# Cek apakah player lagi megang senjata (variabel dari sistem pickup kita kemarin)
		if senjata_sekarang != "":
			eksekusi_menyerang()
	
func eksekusi_menyerang() -> void:
	print("PLAYER NYERANG PAKE: ", senjata_sekarang)
	var tebasan = SABETAN_ENERGI_SCENE.instantiate()
	tebasan.global_transform = global_transform
	tebasan.global_position += -global_transform.basis.z * 1.0 + Vector3(0, 0.5, 0)
	
	get_tree().current_scene.add_child(tebasan)
	
	# OPTIONAL ANIMASI: Bikin model senjata di tangan agak muter/ngayun dikit pas nyerang via kode
	var tween = create_tween()
	tween.tween_property(node_tangan, "rotation:y", deg_to_rad(-45), 0.05) # Ayun cepat
	tween.tween_property(node_tangan, "rotation:y", deg_to_rad(0), 0.1).set_delay(0.05) # Balik normal
	
# IMPROTANT nyerang pake anuan
func ambil_senjata(nama_barang: String) -> void:
	# 1. Cek apakah nama senjata yang diambil terdaftar di Kamus kita
	if DAFTAR_SENJATA.has(nama_barang):
		
		# 2. Kalau player LAGI MEGEGANG senjata lain, HANCURKAN dulu senjata lamanya biar ga numpuk
		if node_senjata_di_tangan != null:
			node_senjata_di_tangan.queue_free()
			
		senjata_sekarang = nama_barang
		print("PLAYER BERHASIL MENGAMBIL: ", senjata_sekarang)
		
		# 3. Ambil blueprint model dari kamus, lalu INSTANTIATE (cetak dinamis)
		var blueprint_model = DAFTAR_SENJATA[nama_barang]
		var model_baru = blueprint_model.instantiate()
		
		# 4. Cemplungin modelnya jadi anak node $Tangan
		$Tangan.add_child(model_baru)
		
		# 5. Simpan memorinya ke variabel biar nanti bisa dihapus kalau ganti senjata
		node_senjata_di_tangan = model_baru
	else:
		print("Eror: Nama senjata '", nama_barang, "' belum didaftarin di Kamus DAFTAR_SENJATA!")
