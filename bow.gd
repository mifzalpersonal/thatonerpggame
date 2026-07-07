extends Node3D

# Ganti ke scene Arrow/Panah yang sudah kita buat sebelumnya
const ARROW_PROJECTILE_SCENE = preload("res://Scene/arrow.tscn")

@onready var muzzle: Marker3D = $Muzzle

@export var attack_cooldown: float = 0.5
var bisa_serang: bool = true

# Variabel untuk menyimpan arah tembakan (Default ke kanan)
var shoot_direction: Vector3 = Vector3.RIGHT

func _process(_delta: float) -> void:
	# 1. LOGIKA MENENTUKAN ARAH HADAP BOW (2.5D Side-scroller)
	if Input.is_action_pressed("ui_right"):
		shoot_direction = Vector3.RIGHT
		rotation.y = 0 # Hadap kanan
	elif Input.is_action_pressed("ui_left"):
		shoot_direction = Vector3.LEFT
		rotation.y = PI # Hadap kiri (putar 180 derajat)

	# 2. LOGIKA MENEMBAK DENGAN COOLDOWN
	if Input.is_action_just_pressed("attack") and bisa_serang:
		shoot_arrow()
		mulai_cooldown()

func shoot_arrow() -> void:
	var arrow_instance = ARROW_PROJECTILE_SCENE.instantiate()
	
	# Atur posisi dan rotasi panah sesuai dengan Muzzle busur
	arrow_instance.global_transform = muzzle.global_transform
	
	# Berikan arah terbang ke panah (variabel 'direction' di script Arrow-mu)
	arrow_instance.direction = shoot_direction
	
	# Masukkan ke root/scene utama agar panah bebas bergerak sendiri
	get_tree().root.add_child(arrow_instance)

# --- FUNGSI JEDA (COOLDOWN) ---
func mulai_cooldown() -> void:
	bisa_serang = false
	var timer = get_tree().create_timer(attack_cooldown)
	timer.timeout.connect(func(): bisa_serang = true)
