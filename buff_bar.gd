extends PanelContainer

@onready var icon_list: HBoxContainer = $Margin/IconList
const STATUS_ICON_TSCN = preload("res://status_icon.tscn")

func _ready() -> void:
	visible = false

func tambah_status_icon(path_gambar: String, durasi: float, id_buff: String) -> void:
	# 1. Jika buff sudah ada, hapus yang lama (refresh)
	if icon_list.has_node(id_buff):
		icon_list.get_node(id_buff).queue_free()
		await get_tree().process_frame
	
	# 2. Buat instance icon baru
	var icon_baru = STATUS_ICON_TSCN.instantiate()
	icon_baru.name = id_buff
	icon_list.add_child(icon_baru)
	
	# 3. Panggil fungsi setup untuk mengirim data gambar & durasi
	icon_baru.setup_icon(path_gambar, durasi)
	
	visible = true
	
	# 4. Tunggu durasi habis lewat timer otomatis di sini untuk trigger hapus dari list
	await get_tree().create_timer(durasi).timeout
	
	if is_instance_valid(icon_baru):
		icon_baru.queue_free()
		await get_tree().process_frame
		
	# Sembunyikan background jika semua buff sudah bersih
	if icon_list.get_child_count() == 0:
		visible = false
