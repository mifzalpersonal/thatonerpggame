extends Area3D

@onready var interaction_label: Label3D = $Label3D

# Variabel penanda apakah player sedang berada di dekat penjual
var player_di_dekat_toko: bool = false

func _ready() -> void:
	# Hubungkan sinyal area masuk dan keluar ke kodingan
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if interaction_label:
		interaction_label.visible = false

func _process(_delta: float) -> void:
	# Jika player di dekat toko dan menekan tombol E
	if player_di_dekat_toko and Input.is_action_just_pressed("interaction"):
		var shop = get_node_or_null("/root/ShopUI")
		if shop:
			shop.buka_toko() # Panggil menu tokomu yang besar kemarin!

# === DETEKSI PLAYER DEKAT MEJA ===
func _on_body_entered(body: Node3D) -> void:
	# Cek apakah yang mendekat adalah player kamu
	if body.name == "Char3" or body.has_method("switch_hud_slot"):
		player_di_dekat_toko = true
		if interaction_label:
			interaction_label.visible = true # Munculkan tulisan "Tekan [E]"

func _on_body_exited(body: Node3D) -> void:
	if body.name == "Char3" or body.has_method("switch_hud_slot"):
		player_di_dekat_toko = false
		if interaction_label:
			interaction_label.visible = false # Sembunyikan tulisan saat player menjauh
