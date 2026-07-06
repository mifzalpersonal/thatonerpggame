extends Area3D

@export var speed: float = 2.5
@export var damage: int = 10
@export var lifetime: float = 2.5 # Total waktu terbang

# Ambil referensi node AnimatedSprite3D yang ada di bawah Area3D
@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D

# Variabel untuk mencatat waktu yang sudah berjalan
var time_elapsed: float = 0.0

# Tentukan ukuran-ukuran skala di sini (X, Y, Z)
var scale_awal: Vector3 = Vector3(5, 5, 5)   # Kecil pas keluar dari laras
var scale_tengah: Vector3 = Vector3(20, 20, 20) # Gede pas di tengah perjalanan
var scale_akhir: Vector3 = Vector3(15, 15, 15)  # Medium sebelum menghilang

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Set skala awal pas pertama kali spawn
	scale = scale_awal
	
	# Putar animasi peluru (ganti "nama_animasi_kamu" sesuai nama di SpriteFrames)
	if animated_sprite:
		animated_sprite.play("Slash")

func _physics_process(delta: float) -> void:
	# 1. Pergerakan maju
	global_translate(global_transform.basis.x * speed * delta)
	
	# 2. Hitung progress waktu (dari 0.0 sampai 1.0)
	time_elapsed += delta
	var progress: float = time_elapsed / lifetime
	
	# Jika waktu habis, hapus objek
	if progress >= 1.0:
		queue_free()
		return
		
	# 3. Logika Perubahan Ukuran (Kecil -> Gede -> Medium)
	if progress < 0.5:
		# Fase Pertama: Dari awal ke tengah (0.0 sampai 0.5)
		var t: float = progress / 0.5
		scale = scale_awal.lerp(scale_tengah, t)
	else:
		# Fase Kedua: Dari tengah ke akhir (0.5 sampai 1.0)
		var t: float = (progress - 0.5) / 0.5
		scale = scale_tengah.lerp(scale_akhir, t)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.name == "Char3": # Sesuaikan sama nama node player lu
		return
		
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
