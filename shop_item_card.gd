extends PanelContainer

signal item_purchased(item_data: Dictionary, button_node: Button)

@onready var item_icon: TextureRect = $VBoxContainer/ItemIcon
@onready var item_name: Label = $VBoxContainer/ItemName
@onready var item_desc: Label = $VBoxContainer/ItemDesc
@onready var buy_button: Button = $VBoxContainer/BuyButton

var current_item_data: Dictionary

# Fungsi untuk mengisi data kartu secara otomatis dari luar
func setup_card(item_data: Dictionary) -> void:
	current_item_data = item_data
	
	item_name.text = item_data["name"]
	item_desc.text = item_data["desc"]
	buy_button.text = "Beli (" + str(item_data["price"]) + " Koin)"
	
	# Load gambar item berdasarkan path di dictionary
	if item_data.has("icon_path") and item_data["icon_path"] != "":
		item_icon.texture = load(item_data["icon_path"])
	
	# Hubungkan sinyal klik tombol
	if not buy_button.pressed.is_connected(_on_buy_pressed):
		buy_button.pressed.connect(_on_buy_pressed)

func _on_buy_pressed() -> void:
	# Kirim data ke toko utama kalau kartu ini diklik
	item_purchased.emit(current_item_data, buy_button)
