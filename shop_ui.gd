extends CanvasLayer

@onready var player_coin_label: Label = $PanelContainer/VBoxContainer/Coin/PlayerCoinLabel
@onready var hbox_container: HBoxContainer = $PanelContainer/VBoxContainer/HBoxContainer
@onready var reroll_button: TextureButton = $TextureButton
@onready var reroll_label: Label = $RerollLabel
@onready var reroll_sprite: AnimatedSprite2D = $TextureButton/AnimatedSprite2D

var card_template = preload("res://shop_item_card.tscn")

func _ready() -> void:
	visible = false
	if reroll_button:
		reroll_button.pressed.connect(_on_reroll_pressed)
		reroll_button.mouse_entered.connect(_on_reroll_hover_in)
		reroll_button.mouse_exited.connect(_on_reroll_hover_out)
		reroll_button.button_down.connect(_on_reroll_button_down)
		reroll_button.button_up.connect(_on_reroll_button_up)
	
	if reroll_sprite:
		reroll_sprite.play("default")

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("Menu"):
		tutup_toko()

func update_toko_ui():
	if player_coin_label:
		player_coin_label.text = str(GameManager.total_currency)
	if reroll_label:
		reroll_label.text = str(GameManager.harga_reroll_sekarang)

func buka_toko():
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	update_toko_ui()
	tampilkan_barang_toko()

func tampilkan_barang_toko():
	# Bersihkan rak dari instance kartu lama
	for child in hbox_container.get_children():
		child.queue_free()
	
	# Jika list kosong, buat barang baru
	if GameManager.isi_toko_level_ini.size() == 0:
		GameManager.buat_rak_toko_baru()
		
	# Render kartu dari list
	for item in GameManager.isi_toko_level_ini:
		if item is Dictionary:
			var card_instance = card_template.instantiate()
			hbox_container.add_child(card_instance)
			
			# Setup kartu (termasuk pengecekan status is_purchased di dalam setup_card)
			card_instance.setup_card(item) 
			card_instance.item_purchased.connect(_on_item_bought)

func _on_item_bought(item: Dictionary, card_node: PanelContainer) -> void:
	var sukses_beli = GameManager.buy_item(item)
	
	if sukses_beli:
		# --- JANGAN DI-ERASE ---
		# Tandai di data bahwa sudah terbeli agar saat dibuka lagi tetap statusnya terbeli
		item["is_purchased"] = true
		
		# Update visual kartu agar terkunci/abu-abu
		if card_node.has_method("set_terbeli"):
			card_node.set_terbeli()
		
		update_toko_ui()
	else:
		print("TOKO UI: Koin kurang untuk membeli ", item["name"])

# ... (Fungsi reroll & animasi tetap sama) ...
func _on_reroll_pressed() -> void:
	if GameManager.request_reroll():
		update_toko_ui()
		tampilkan_barang_toko()

func _on_reroll_hover_in() -> void:
	if reroll_sprite and reroll_sprite.sprite_frames.has_animation("Hover"): reroll_sprite.play("Hover")

func _on_reroll_hover_out() -> void:
	if reroll_sprite and reroll_sprite.sprite_frames.has_animation("default"): reroll_sprite.play("default")

func _on_reroll_button_down() -> void:
	if reroll_sprite and reroll_sprite.sprite_frames.has_animation("Hover"): reroll_sprite.play("Hover")

func _on_reroll_button_up() -> void:
	if reroll_button and reroll_sprite:
		if reroll_button.is_hovered() and reroll_sprite.sprite_frames.has_animation("Hover"): reroll_sprite.play("Hover")
		elif reroll_sprite.sprite_frames.has_animation("default"): reroll_sprite.play("default")

func tutup_toko():
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
