extends CanvasLayer

@onready var player_coin_label: Label = $PanelContainer/VBoxContainer/PlayerCoinLabel
@onready var hbox_container: HBoxContainer = $PanelContainer/VBoxContainer/HBoxContainer
@onready var reroll_button: Button = $RerollButton # <- Ambil referensi tombol baru

var card_template = preload("res://shop_item_card.tscn")

func _ready() -> void:
	visible = false
	# Hubungkan fungsi reroll ke tombol saat game dimulai
	if reroll_button:
		reroll_button.pressed.connect(_on_reroll_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("Menu"):
		tutup_toko()

# Di dalam ShopUI.gd pada fungsi update_toko_ui()
func update_toko_ui():
	player_coin_label.text = "Koin Kamu: " + str(GameManager.total_currency)
	if reroll_button:
		# GANTI BAGIAN INI AGAR MENGAMBIL 'harga_reroll_sekarang' BUKAN 'harga_reroll_awal'
		reroll_button.text = "Acak Ulang Barang (Biaya: " + str(GameManager.harga_reroll_sekarang) + " Koin)"

func buka_toko():
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	update_toko_ui()
	tampilkan_barang_toko()

func tampilkan_barang_toko():
	# Bersihkan rak dari kartu-kartu lama terlebih dahulu
	for child in hbox_container.get_children():
		child.queue_free()
	
	if GameManager.isi_toko_level_ini.size() == 0:
		GameManager.buat_rak_toko_baru()
		
	# Render ulang 4 kartu baru hasil gacha dari GameManager
	for item in GameManager.isi_toko_level_ini:
		if item is Dictionary:
			var card_instance = card_template.instantiate()
			hbox_container.add_child(card_instance)
			card_instance.setup_card(item)
			card_instance.item_purchased.connect(_on_item_bought)

func _on_item_bought(item: Dictionary, card_node: PanelContainer) -> void:
	var sukses_beli = GameManager.buy_item(item)
	
	if sukses_beli:
		# Panggil fungsi set_terbeli yang ada di dalam script kartu baru kita
		if card_node.has_method("set_terbeli"):
			card_node.set_terbeli()
		update_toko_ui()
	else:
		print("TOKO UI: Koin kurang untuk membeli ", item["name"])

# --- TRIGGER SAAT TOMBOL REROLL DIKLIK ---
func _on_reroll_pressed() -> void:
	# Minta izin potong koin dan acak data ke GameManager
	var sukses_reroll = GameManager.request_reroll()
	
	if sukses_reroll:
		# Update info koin baru di screen
		update_toko_ui()
		# Gambar ulang 4 kartu baru di layar player secara live!
		tampilkan_barang_toko()
	else:
		# Efek visual/teks peringatan jika koin kurang bisa ditaruh di sini
		print("TOKO UI: Gagal reroll, koin kamu tidak cukup!")

func tutup_toko():
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 
	print("TOKO: Toko ditutup.")
