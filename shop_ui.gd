extends CanvasLayer

# Label untuk menampilkan sisa koin yang kamu miliki secara real-time
@onready var player_coin_label: Label = $PanelContainer/VBoxContainer/Coin/PlayerCoinLabel
@onready var hbox_container: HBoxContainer = $PanelContainer/VBoxContainer/HBoxContainer
@onready var reroll_button: TextureButton = $TextureButton

# Label di dalam TextureButton yang HANYA menampilkan angka harga reroll saat ini
@onready var reroll_label: Label = $RerollLabel

# Ambil referensi ke AnimatedSprite2D yang ada di dalam TextureButton
@onready var reroll_sprite: AnimatedSprite2D = $TextureButton/AnimatedSprite2D

var card_template = preload("res://shop_item_card.tscn")

func _ready() -> void:
	visible = false
	
	# Hubungkan fungsi reroll dan animasi ke tombol saat game dimulai
	if reroll_button:
		reroll_button.pressed.connect(_on_reroll_pressed)
		
		# --- SINYAL ANIMASI HOVER & KLIK ---
		reroll_button.mouse_entered.connect(_on_reroll_hover_in)
		reroll_button.mouse_exited.connect(_on_reroll_hover_out)
		reroll_button.button_down.connect(_on_reroll_button_down)
		reroll_button.button_up.connect(_on_reroll_button_up)
	
	# Set animasi awal ke default/diam saat game mulai
	if reroll_sprite:
		reroll_sprite.play("default")

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("Menu"):
		tutup_toko()

# Fungsi untuk memperbarui seluruh teks pada elemen UI Toko
func update_toko_ui():
	# 1. Menampilkan sisa koin milik Player dari GameManager (berupa angka saja)
	if player_coin_label:
		player_coin_label.text = str(GameManager.total_currency)
	
	# 2. Menampilkan HANYA ANGKA harga reroll pada Label di dalam tombol
	if reroll_label:
		reroll_label.text = str(GameManager.harga_reroll_sekarang)

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
		# Update info koin baru dan harga gacha baru di screen secara live!
		update_toko_ui()
		# Gambar ulang 4 kartu baru di layar player secara live!
		tampilkan_barang_toko()
	else:
		# Efek visual/teks peringatan jika koin kurang bisa ditaruh di sini
		print("TOKO UI: Gagal reroll, koin kamu tidak cukup!")

# --- LOGIKA ANIMASI UNTUK SPRITESHEET DI TOMBOL ---
func _on_reroll_hover_in() -> void:
	if reroll_sprite and reroll_sprite.sprite_frames.has_animation("Hover"):
		reroll_sprite.play("Hover")

func _on_reroll_hover_out() -> void:
	if reroll_sprite and reroll_sprite.sprite_frames.has_animation("default"):
		reroll_sprite.play("default")

func _on_reroll_button_down() -> void:
	if reroll_sprite and reroll_sprite.sprite_frames.has_animation("Hover"):
		reroll_sprite.play("Hover")

func _on_reroll_button_up() -> void:
	if reroll_button and reroll_sprite:
		if reroll_button.is_hovered() and reroll_sprite.sprite_frames.has_animation("Hover"):
			reroll_sprite.play("Hover")
		elif reroll_sprite.sprite_frames.has_animation("default"):
			reroll_sprite.play("default")

func tutup_toko():
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 
	print("TOKO: Toko ditutup.")
