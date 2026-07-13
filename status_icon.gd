extends VBoxContainer

@onready var icon_texture: TextureRect = $IconTexture
@onready var duration_label: Label = $DurationLabel

var waktu_tersisa: float = 0.0
var total_durasi: float = 0.0

func _ready() -> void:
	# 1. SETUP ANIMASI MUNCUL (Pop-up Effect)
	# Menggunakan Vector2 karena ini adalah Node UI 2D
	scale = Vector2.ZERO
	
	var tween = create_tween().set_parallel(false)
	# Membesar melebihi ukuran asli sedikit (1.15) selama 0.15 detik untuk efek bouncy
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Kembalikan ke ukuran normal (1.0) dengan cepat
	tween.tween_property(self, "scale", Vector2.ONE, 0.05)

func setup_icon(path_gambar: String, durasi: float) -> void:
	waktu_tersisa = durasi
	total_durasi = durasi
	
	# Load gambar ke TextureRect baru
	var info_gambar = load(path_gambar)
	if info_gambar and icon_texture:
		icon_texture.texture = info_gambar
		
	# Tampilkan angka pertama
	_update_label_teks()

func _process(delta: float) -> void:
	if waktu_tersisa > 0.0:
		waktu_tersisa -= delta
		_update_label_teks()
		
		# Animasi kedip-kedip tipis saat waktu mau habis (sisa 2 detik)
		if waktu_tersisa <= 2.0:
			modulate.a = 0.4 if Engine.get_frames_drawn() % 10 < 5 else 1.0
	else:
		set_process(false)

func _update_label_teks() -> void:
	if duration_label:
		# Format string ".1f" artinya hanya menampilkan 1 angka di belakang koma (misal: 4.5s)
		duration_label.text = "%.1fs" % max(waktu_tersisa, 0.0)
