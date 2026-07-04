extends Node3D

var base_max_hp: int = 3    # HP awal tanpa gear (misal 3 nyawa)
var bonus_max_hp: int = 0     # Tambahan kapasitas dari gear
var current_hp: int = 3

@onready var game_ui = $GUI/GameUI

# Helper untuk menghitung total kapasitas HP saat ini
func get_total_max_hp() -> int:
	return base_max_hp + bonus_max_hp

func _ready() -> void:
	# Awal game, setup UI dengan total HP awal
	game_ui.setup_hearts(get_total_max_hp(), current_hp)

# Fungsi terkena damage
func take_damage(amount: int) -> void:
	current_hp -= amount
	current_hp = clamp(current_hp, 0, get_total_max_hp())
	
	game_ui.update_hearts(current_hp)

# ==========================================
# REKAYASA FITUR GEAR UP (TAMBAH KAPASITAS)
# ==========================================
func equip_gear() -> void:
	print("Gear dipakai! Kapasitas HP bertambah.")
	bonus_max_hp = 2 # Misal dapat tambahan 2 slot nyawa dari armor/gear
	
	# Karena kapasitas bertambah, kita isi juga nyawa tambahannya (opsional)
	current_hp += 2 
	
	# Panggil SETUP lagi karena struktur jumlah TextureRect di HBox-nya berubah
	game_ui.setup_hearts(get_total_max_hp(), current_hp)

func unequip_gear() -> void:
	print("Gear dilepas! Kapasitas HP berkurang.")
	bonus_max_hp = 0
	
	# Jika setelah dilepas HP sekarang melebihi batas maksimal yang baru
	if current_hp > get_total_max_hp():
		current_hp = get_total_max_hp()
		
	game_ui.setup_hearts(get_total_max_hp(), current_hp)

# ==========================================
# TOMBOL TESTING (Gunakan Keyboard)
# ==========================================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Tombol SPASI
		take_damage(1) # Kurang 1 nyawa
		
	if event.is_action_pressed("ui_right"): # Tombol Panah Kanan
		equip_gear() # Simulasi pakai gear
		
	if event.is_action_pressed("ui_left"): # Tombol Panah Kiri
		unequip_gear() # Simulasi lepas gear
