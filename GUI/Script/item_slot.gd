extends PanelContainer

# Referensi ke node anak
@onready var control_container = $ControlContainer
@onready var slot_background = $ControlContainer/SlotBackground
@onready var item_icon = $ItemIcon

var is_full: bool = false
var current_item_name: String = ""

# Status apakah slot ini sedang aktif dipakai/dipilih oleh player
var is_active: bool = false : set = set_active

func _ready() -> void:
	clear_slot()
	
	# 1. Pastikan Centered aktif, lalu lempar posisi sprite tepat ke TENGAH parent
	slot_background.centered = true
	slot_background.position = size / 2
	
	# 2. RUMUS AUTO-SCALE: Paksa ukuran AnimatedSprite2D mengikuti ukuran PanelContainer
	# Diubah dari "pasif" menjadi "default" sesuai nama di editor kamu
	var frame_texture = slot_background.sprite_frames.get_frame_texture("Default", 0)
	if frame_texture != null:
		var sprite_size = frame_texture.get_size()
		slot_background.scale = size / sprite_size
	
	# Jalankan animasi "default" (diam/tidak aktif) di awal game
	slot_background.play("Default")

# Fungsi Setter yang dipanggil saat player menekan tombol 1 atau 2
func set_active(value: bool) -> void:
	is_active = value
	
	# PENGAMAN: Jika game baru jalan dan node belum siap, tunggu sampai siap
	if not is_node_ready():
		await ready
		
	if is_active:
		slot_background.stop() 
		slot_background.play("Aktif") # Memutar animasi "aktif" saat dipilih
		print(name, " memutar animasi: Aktif")
	else:
		slot_background.stop()
		slot_background.play("Default") # Kembali ke animasi "default" saat tidak dipilih
		slot_background.frame = 0 
		print(name, " memutar animasi: Default")

func set_item(item_texture: Texture2D, item_name: String) -> void:
	if item_texture != null:
		item_icon.texture = item_texture
		item_icon.show()
		is_full = true
		current_item_name = item_name

func clear_slot() -> void:
	item_icon.texture = null
	item_icon.hide()
