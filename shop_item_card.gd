extends PanelContainer

@onready var item_icon: TextureRect = $CardContent/VBoxContainer/ItemIcon
@onready var item_name: Label = $CardContent/VBoxContainer/ItemName
@onready var item_price: Label = $CardContent/VBoxContainer/ItemPrice # <- Node Harga Baru
@onready var item_desc: MarginContainer = $CardContent/VBoxContainer/ItemDesc # <- Menjadi MarginContainer
@onready var item_desc_label: Label = $CardContent/VBoxContainer/ItemDesc/ItemDescLabel # <- Teks di dalam Margin
@onready var info_button: Button = $CardContent/InfoButton

signal item_purchased(item_data: Dictionary, card_node: PanelContainer)

var current_item_data: Dictionary = {}
var is_sold_out: bool = false
var is_showing_desc: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	
	if info_button:
		info_button.pressed.connect(_on_info_pressed)
		
	pivot_offset = size / 2
	item_desc.visible = false

func setup_card(item: Dictionary) -> void:
	current_item_data = item
	
	# --- MENGUBAH TULISAN NAMA & HARGA (DIPISAH VERTIKAL) ---
	item_name.text = item["name"]
	item_price.text = str(item["price"]) + " Koin"
	
	# Ambil teks deskripsi ke label dalam margin
	item_desc_label.text = item["desc"]
	item_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	if item["icon_path"] != "":
		item_icon.texture = load(item["icon_path"])
		
	aplikasikan_warna_rarity(item["rarity"])

func aplikasikan_warna_rarity(rarity: String) -> void:
	var warna_kasta: Color
	match rarity:
		"common": warna_kasta = Color.GREEN
		"rare": warna_kasta = Color.DEEP_SKY_BLUE
		"legendary": warna_kasta = Color.GOLD
		_: warna_kasta = Color.WHITE
			
	# Warnai teks Nama dan Harga secara serasi
	item_name.add_theme_color_override("font_color", warna_kasta)
	item_price.add_theme_color_override("font_color", warna_kasta)
	
	var style_box = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if style_box:
		style_box.border_color = warna_kasta
		add_theme_stylebox_override("panel", style_box)

# --- ANIMASI FLIP DESKRIPSI PENH ---
func _on_info_pressed() -> void:
	if is_sold_out: return
	
	is_showing_desc = not is_showing_desc
	pivot_offset = size / 2
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	scale = Vector2(0.95, 0.95)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	
	if is_showing_desc:
		info_button.text = "X"
		
		# Memudarkan Nama, Harga, dan Icon
		tween.tween_property(item_name, "modulate:a", 0.0, 0.15)
		tween.tween_property(item_price, "modulate:a", 0.0, 0.15)
		tween.tween_property(item_icon, "modulate:a", 0.0, 0.15)
		
		await get_tree().create_timer(0.15).timeout
		item_name.visible = false
		item_price.visible = false
		item_icon.visible = false
		
		# Memunculkan kotak Margin deskripsi
		item_desc.visible = true
		item_desc.modulate.a = 0.0
		var tween_in = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween_in.tween_property(item_desc, "modulate:a", 1.0, 0.2)
		
	else:
		info_button.text = "?"
		
		tween.tween_property(item_desc, "modulate:a", 0.0, 0.15)
		
		await get_tree().create_timer(0.15).timeout
		item_desc.visible = false
		
		item_name.visible = true
		item_price.visible = true
		item_icon.visible = true
		
		var tween_out = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween_out.tween_property(item_name, "modulate:a", 1.0, 0.2)
		tween_out.tween_property(item_price, "modulate:a", 1.0, 0.2)
		tween_out.tween_property(item_icon, "modulate:a", 1.0, 0.2)

func _on_gui_input(event: InputEvent) -> void:
	if is_sold_out: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_local_mouse_position()
		if info_button and info_button.get_rect().has_point(mouse_pos):
			return
			
		if is_showing_desc:
			return
			
		item_purchased.emit(current_item_data, self)

func set_terbeli() -> void:
	is_sold_out = true
	item_name.text = "TERBELI!"
	item_name.visible = true
	item_name.modulate.a = 1.0
	item_price.visible = false
	item_icon.visible = false
	item_desc.visible = false
	
	if info_button:
		info_button.disabled = true
		info_button.visible = false
		
	modulate = Color(0.5, 0.5, 0.5, 0.6)
