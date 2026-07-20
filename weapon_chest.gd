extends Area3D

const weapon_drop = preload("res://WeaponDrop.tscn")

const daftar_senjata = [
	"hugs",
	"hugs_fire",
	"katana",
	"sword_slim",
	"sword_slim_nature",
	"bow"
]

var udah_kebuka : bool = false
var player_deket : CharacterBody3D = null

# Ambil referensi ke AnimationPlayer di Inspector/Hierarchy
@onready var anim_player: AnimationPlayer = $"../../AnimationPlayer"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_kalomasuk)
	body_exited.connect(_kalokeluar)
	$PetunjukE.visible = false 
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if udah_kebuka == false and player_deket != null:
		if Input.is_action_just_pressed("interaction") :
			buka_peti()
			print("you pressed E")
		pass

func _kalomasuk(body : Node3D) -> void:
	if udah_kebuka == false and body is CharacterBody3D:
		player_deket = body
		$PetunjukE.visible = true
		print("lu deket chest")

func _kalokeluar(body : Node3D) -> void:
	if body is CharacterBody3D:
		player_deket = null
		$PetunjukE.visible = false
		print("lu ngga deket chest")

func buka_peti() -> void:
	udah_kebuka = true
	$PetunjukE.visible = false
	
	# === Bagian Animasi Peti Terbuka ===
	if anim_player and anim_player.has_animation("Open"):
		anim_player.play("Open")
		print("SISTEM: Memutar animasi Open Peti!")
	else:
		push_warning("Peringatan: Node AnimationPlayer atau animasi bernama 'Open' tidak ditemukan!")
	
	# === Logika Gacha Penentuan Senjata ===
	var indeks_acak = randi() % daftar_senjata.size()
	var senjata_terpilih = daftar_senjata[indeks_acak]
	print("📦 GACHA RESULT: ", senjata_terpilih)
	
	# Instantiate objek senjata
	var hasil_gacha = weapon_drop.instantiate()
	
	# 🔥 SOLUSI 1: Tentukan nama senjata DULUAN sebelum masuk ke Scene Tree dunia game
	# Ini supaya fungsi _ready() di WeaponDrop melahirkan model 3D yang tepat, bukan Katana default.
	hasil_gacha.nama_senjata = senjata_terpilih
	
	# Masukkan senjata ke dunia game
	get_parent().add_child(hasil_gacha)
	
	# 🔥 SOLUSI 2: Samakan rotasi 3D (Basis) senjata agar persis menghadap sesuai arah peti
	hasil_gacha.global_transform.basis = global_transform.basis
	
	# Posisikan senjata melayang 1.5 meter tegak lurus ke atas kepala peti
	hasil_gacha.global_position = global_position + (global_transform.basis.y * 1.5)
	
	print("📦 CHEST GACHA: Sukses spawn ", senjata_terpilih, " menghadap sesuai arah peti!")
