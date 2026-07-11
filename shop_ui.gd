extends CanvasLayer

@onready var player_coin_label: Label = $PanelContainer/VBoxContainer/PlayerCoinLabel
@onready var hbox_container: HBoxContainer = $PanelContainer/VBoxContainer/HBoxContainer

var card_template = preload("res://shop_item_card.tscn")

func _ready() -> void:
	visible = false

# === DETEKSI TOMBOL ESC SECARA LIVE ===
func _unhandled_input(event: InputEvent) -> void:
	# Jika menu toko sedang terbuka DAN player menekan tombol ESC (Escape)
	if visible and event.is_action_pressed("Menu"):
		tutup_toko()

func update_toko_ui():
	player_coin_label.text = "Koin Kamu: " + str(GameManager.total_currency)

func acak_barang_toko():
	for child in hbox_container.get_children():
		child.queue_free()
	
	var pool_item = GameManager.MASTER_ITEMS.duplicate()
	pool_item.shuffle()
	
	var jumlah_slot = clampi(pool_item.size(), 0, 4)
	for i in range(jumlah_slot):
		var item = pool_item[i]
		
		var card_instance = card_template.instantiate()
		hbox_container.add_child(card_instance)
		card_instance.setup_card(item)
		card_instance.item_purchased.connect(_on_item_bought)

func _on_item_bought(item: Dictionary, button_node: Button) -> void:
	var harga = item["price"]
	
	if GameManager.total_currency >= harga:
		GameManager.total_currency -= harga
		GameManager.currency_changed.emit(GameManager.total_currency)
		
		match item["id"]:
			"hp_potion": print("TOKO: Beli HP!")
			"atk_buff": print("TOKO: Beli ATK!")
		
		button_node.disabled = true
		button_node.text = "TERBELI!"
		
		update_toko_ui()
	else:
		print("TOKO: Koin kurang untuk membeli ", item["name"])

func buka_toko():
	visible = true
	get_tree().paused = true
	update_toko_ui()
	acak_barang_toko()

func tutup_toko():
	visible = false
	get_tree().paused = false
	print("TOKO: Toko ditutup lewat tombol ESC.")
