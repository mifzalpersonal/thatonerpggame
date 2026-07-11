extends CanvasLayer # atau CanvasLayer (sesuaikan dengan tipe root node UI-mu)

# Pastikan path ini sesuai dengan susunan node UI koin kamu di panel Scene
@onready var coin_label: Label = $CoinLabel

func _ready() -> void:
	# 1. Hubungkan ke sinyal bawaan GameManager kamu (currency_changed)
	if GameManager.has_signal("currency_changed"):
		GameManager.currency_changed.connect(_on_currency_changed)
	
	# 2. Amankan antrean frame agar node siap, lalu ambil data total_currency ter-update
	await get_tree().process_frame
	_update_coin_display(GameManager.total_currency)

# Fungsi yang otomatis terpicu saat musuh mati dan memancarkan sinyal currency_changed
func _on_currency_changed(new_amount: int) -> void:
	_update_coin_display(new_amount)

# Fungsi untuk memperbarui angka di layar monitor game
func _update_coin_display(amount: int) -> void:
	if coin_label:
		coin_label.text = str(amount)
		print("UI COIN STATUS: Angka koin di layar berhasil update ke -> ", amount)
