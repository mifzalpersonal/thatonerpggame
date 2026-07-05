extends Camera3D

var time = 0.0
@export var sway_speed: float = 1.0   # Kecepatan gerak napas
@export var sway_amount: float = 0.05 # Seberapa jauh gesernya (dikit aja)

# Variabel buat nyimpen posisi awal kamera kamu di editor
var posisi_asal: Vector3

func _ready():
	# Catat posisi asli kamera yang sudah kamu atur di editor
	posisi_asal = position

func _process(delta):
	time += delta * sway_speed
	
	# Goyangannya ditambahkan ke POSISI ASAL, bukan dimulai dari 0
	position.x = posisi_asal.x + (sin(time) * sway_amount)
	position.y = posisi_asal.y + (cos(time * 0.5) * sway_amount)
