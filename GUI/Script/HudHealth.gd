extends Control

const HEART_FULL = preload("res://GUI/Asset/Health.png")
const HEART_EMPTY = preload("res://GUI/Asset/Health0.png")

@onready var heart_container = $HeartContainer

# HANYA dipanggil saat game mulai ATAU saat KAPASITAS HP berubah (Gear Up)
func setup_hearts(max_hp: int, current_hp: float) -> void:
	if not is_inside_tree():
		await ready
		
	# Bersihkan icon nyawa yang lama
	for child in heart_container.get_children():
		child.queue_free()
		
	# Bikin TextureRect baru sesuai kapasitas maksimal
	for i in range(max_hp):
		var heart_rect = TextureRect.new()
		heart_rect.name = "Heart_" + str(i)
		
		# Set ukuran agar konsisten
		heart_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		heart_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		heart_container.add_child(heart_rect)
	
	# Beri jeda 1 frame tipis agar queue_free() selesai membersihkan node lama,
	# baru kita update tampilannya dengan aman.
	await get_tree().process_frame
	update_hearts(current_hp)


# Dipanggil TIAP KALI kena damage atau healing (Jangan buat node baru di sini!)
func update_hearts(current_hp: float) -> void:
	var hearts = heart_container.get_children()
	
	for i in range(hearts.size()):
		# Menggunakan float(i) karena HP mu berupa float (pecahan)
		if float(i) < current_hp:
			hearts[i].texture = HEART_FULL
		else:
			hearts[i].texture = HEART_EMPTY
