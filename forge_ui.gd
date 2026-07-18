extends Control

# Sisi Latar Belakang (Render 3D)
@onready var preview_pivot: Node3D = $SubViewportContainer/SubViewport/GridMap/WeaponPreviewPivot

# Sisi Kanan / UI Elements Utama
@onready var weapon_name_label: Label = $WeaponNameLabel
@onready var dmg_label: Label = $Stats/Damage/Label
@onready var crit_label: Label = $Stats/Crit/Label
@onready var info_label: Label = $InfoLabel
@onready var close_button: Button = $CloseButton

# Info Peluang Gacha
@onready var chance_label: Label = $ChanceLabel
@onready var chance_info: RichTextLabel = $ChanceLabel/ChanceInfo

# Tombol Utama & Cost di bagian bawah PanelKanan
@onready var confirm_button: Button = $ConfirmButton
@onready var cost_node: Control = $Cost
@onready var cost_label: Label = $Cost/CostLabel

# UI Saldo Uang Saat Ini (Pojok Kiri Atas)
@onready var current_currency_label: Label = $Uang/HBoxContainer/Currency

# Tombol Opsi Menu Tengah (Pedang & Anvil)
@onready var btn_option_level: Button = $SwitchOptions/ForgeButton
@onready var btn_option_rarity: Button = $SwitchOptions/ForgeRarityButton

# Tombol Pilihan Slot DI DALAM UI FORGE
@onready var btn_slot_1: Button = $WeaponSlot/Slot1
@onready var btn_slot_2: Button = $WeaponSlot/Slot2

# ==========================================
# 📦 VARIABEL DATA UI FORGE
# ==========================================
var nama_senjata_aktif: String = ""
var stats_senjata: Resource = null 
var biaya_nempa_level: int = 100
var biaya_nempa_rarity: int = 100
var slot_terpilih_forge: int = 1
var node_tangan_player: Node = null

# Pengali stat visual untuk kalkulasi preview di UI
const DAMAGE_PER_LEVEL: int = 5
const CRIT_PER_LEVEL: float = 0.01 

enum MenuState { HUB, MENU_LEVEL, MENU_RARITY }
var current_state: MenuState = MenuState.HUB

const RARITY_COLORS = {
	"Common": "#ffffff", "Uncommon": "#1ee655", "Rare": "#00bfff", "Epic": "#b026ff", "Legendary": "#ff8c00"
}

# ==========================================
# ⚙️ SIKLUS UTAMA (LIFECYCLE)
# ==========================================
func _ready() -> void:
	if close_button: close_button.pressed.connect(_on_close_button_pressed)
	if confirm_button: confirm_button.pressed.connect(_on_confirm_button_pressed)
	if btn_slot_2: btn_slot_2.pressed.connect(func(): ganti_slot_senjata_player(2))
		
	visible = false

func _process(delta: float) -> void:
	if preview_pivot and preview_pivot.get_child_count() > 0:
		preview_pivot.rotate_y(delta * 0.6)

# ==========================================
# 🔌 COUPLING SIGNALS DARI EDITOR
# ==========================================
func _on_forge_button_pressed() -> void:
	current_state = MenuState.MENU_LEVEL
	update_tampilan_ui()

func _on_forge_rarity_button_pressed() -> void:
	current_state = MenuState.MENU_RARITY
	update_tampilan_ui()

func _on_slot_1_pressed() -> void:
	ganti_slot_senjata_player(1)

# ==========================================
# 🛠️ FUNGSI INTERAKSI UTAMA NPC
# ==========================================
func open_forge_menu(player_node: Node = null, _dummy_index: int = 0) -> void:
	visible = true
	get_tree().paused = true 
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	current_state = MenuState.HUB
	
	node_tangan_player = null
	
	if player_node != null:
		if player_node.has_node("Tangan"):
			node_tangan_player = player_node.get_node("Tangan")
		elif player_node.name == "Tangan" or player_node.has_method("get_nama_senjata_di_slot"):
			node_tangan_player = player_node
			
	if node_tangan_player == null:
		var player_backup = get_tree().get_first_node_in_group("Player")
		if player_backup:
			if player_backup.has_node("Tangan"):
				node_tangan_player = player_backup.get_node("Tangan")
			elif "slot_senjata" in player_backup:
				node_tangan_player = player_backup

	if node_tangan_player != null and "slot_senjata" in node_tangan_player:
		if btn_slot_1: btn_slot_1.disabled = (node_tangan_player.slot_senjata[0] == "")
		if btn_slot_2: btn_slot_2.disabled = (node_tangan_player.slot_senjata[1] == "")
		
		var slot_awal = 1
		if "slot_aktif" in node_tangan_player:
			slot_awal = node_tangan_player.slot_aktif + 1
		
		muat_senjata_forge(slot_awal)
	else:
		tampilkan_ui_kosong()

func ganti_slot_senjata_player(nomor_slot: int) -> void:
	if node_tangan_player == null: return
	
	var indeks_baru = nomor_slot - 1
	if "slot_aktif" in node_tangan_player:
		node_tangan_player.slot_aktif = indeks_baru
		
		if node_tangan_player.has_method("ganti_senjata"):
			node_tangan_player.ganti_senjata()
		elif node_tangan_player.has_method("_update_weapon_visual"):
			node_tangan_player._update_weapon_visual()
			
	muat_senjata_forge(nomor_slot)

func muat_senjata_forge(nomor_slot: int) -> void:
	if node_tangan_player == null or not "slot_senjata" in node_tangan_player: 
		tampilkan_ui_kosong()
		return
		
	slot_terpilih_forge = nomor_slot
	var indeks = nomor_slot - 1
	var nama_senjata = node_tangan_player.slot_senjata[indeks]
	
	if nama_senjata == "":
		tampilkan_ui_kosong()
		return
		
	nama_senjata_aktif = nama_senjata
	
	if "database_stats" in node_tangan_player and node_tangan_player.database_stats.has(nama_senjata):
		stats_senjata = node_tangan_player.database_stats[nama_senjata]
		update_preview_3d_senjata()
		update_tampilan_ui()
	else:
		if node_tangan_player.has_node("node_senjata_di_tangan") and "stats" in node_tangan_player.node_senjata_di_tangan:
			stats_senjata = node_tangan_player.node_senjata_di_tangan.stats
			update_preview_3d_senjata()
			update_tampilan_ui()
		else:
			tampilkan_ui_kosong()
			
	if btn_slot_1 and btn_slot_2:
		btn_slot_1.modulate = Color(1.5, 1.5, 1.5) if nomor_slot == 1 else Color(1, 1, 1)
		btn_slot_2.modulate = Color(1.5, 1.5, 1.5) if nomor_slot == 2 else Color(1, 1, 1)

func tampilkan_ui_kosong() -> void:
	stats_senjata = null
	nama_senjata_aktif = ""
	weapon_name_label.text = "Tidak Ada Senjata"
	dmg_label.text = "-"
	crit_label.text = "-"
	confirm_button.disabled = true
	if cost_node: cost_node.visible = false

func update_preview_3d_senjata() -> void:
	if preview_pivot == null or nama_senjata_aktif == "": return
	for child in preview_pivot.get_children(): child.queue_free()
		
	var path_senjata = "res://" + nama_senjata_aktif + ".tscn"
	if ResourceLoader.exists(path_senjata):
		var blueprint = load(path_senjata)
		var kloning_senjata = blueprint.instantiate()
		preview_pivot.add_child(kloning_senjata)
		kloning_senjata.position = Vector3(0.0, -0.5, 0.0) 
		kloning_senjata.scale = Vector3(0.8, 0.8, 0.8)
		kloning_senjata.set_process(false)
		kloning_senjata.set_physics_process(false)

func update_tampilan_ui() -> void:
	if current_currency_label:
		current_currency_label.text = str(GameManager.total_currency)

	if stats_senjata == null: return
	
	var nama_rarity = stats_senjata.get_rarity_name()
	weapon_name_label.text = stats_senjata.weapon_name + " (Forge +" + str(stats_senjata.forge_level) + ")\n[" + nama_rarity + "]"
	weapon_name_label.modulate = Color(RARITY_COLORS.get(nama_rarity, "#ffffff"))
	
	var dmg_sekarang = stats_senjata.total_damage
	var crit_sekarang = stats_senjata.crit_chance * 100
	
	# PERBAIKAN: Biaya naik setiap kelipatan 4 level (integer division)
	biaya_nempa_level = (1 + (stats_senjata.forge_level / 4)) * 100
	biaya_nempa_rarity = 100 

	confirm_button.disabled = false
	chance_label.visible = false
	chance_info.visible = false

	match current_state:
		MenuState.HUB:
			info_label.text = "Menu Forge"
			dmg_label.text = str(dmg_sekarang)
			crit_label.text = str(crit_sekarang) + "%"
			confirm_button.text = "Pilih Opsi Terlebih Dahulu"
			confirm_button.disabled = true
			if cost_node: cost_node.visible = false
			
		MenuState.MENU_LEVEL:
			info_label.text = "Upgrade Senjata"
			if cost_node: cost_node.visible = true
			
			if stats_senjata.forge_level >= 24:
				dmg_label.text = str(dmg_sekarang) + " ---> MAX"
				crit_label.text = str(crit_sekarang) + "% ---> MAX"
				cost_label.text = "MAX"
				confirm_button.text = "MAKSIMAL!"
				confirm_button.disabled = true
			else:
				dmg_label.text = str(dmg_sekarang) + " ---> " + str(dmg_sekarang + DAMAGE_PER_LEVEL)
				crit_label.text = str(crit_sekarang) + "% ---> " + str(crit_sekarang + (CRIT_PER_LEVEL * 100)) + "%"
				cost_label.text = str(biaya_nempa_level)
				confirm_button.text = "Tempa Level"
			
		MenuState.MENU_RARITY:
			info_label.text = "Upgrade Rarity"
			if cost_node: cost_node.visible = true
			
			dmg_label.text = str(dmg_sekarang)
			crit_label.text = str(crit_sekarang) + "%"
			
			chance_label.visible = true
			chance_info.visible = true
			
			var c_common = stats_senjata.chance_common * 100
			var c_uncommon = stats_senjata.chance_uncommon * 100
			var c_rare = stats_senjata.chance_rare * 100
			var c_epic = stats_senjata.chance_epic * 100
			var c_legendary = stats_senjata.chance_legendary * 100
			
			# PERBAIKAN: Format teks peluang gacha menggunakan BBCode warna per kasta
			chance_info.text = "[color=%s]C: %d%%[/color] | [color=%s]U: %d%%[/color] | [color=%s]R: %d%%[/color] | [color=%s]E: %d%%[/color] | [color=%s]L: %d%%[/color]" % [
				RARITY_COLORS["Common"], c_common,
				RARITY_COLORS["Uncommon"], c_uncommon,
				RARITY_COLORS["Rare"], c_rare,
				RARITY_COLORS["Epic"], c_epic,
				RARITY_COLORS["Legendary"], c_legendary
			]
			
			cost_label.text = str(biaya_nempa_rarity)
			confirm_button.text = "Kocok Kasta"

func _on_confirm_button_pressed() -> void:
	if stats_senjata == null: return
	
	match current_state:
		MenuState.MENU_LEVEL:
			if stats_senjata.forge_level >= 24: return
			if GameManager.total_currency < biaya_nempa_level:
				print("❌ Koin tidak cukup!")
				return
			
			GameManager.total_currency -= biaya_nempa_level
			stats_senjata.forge_level += 1
			
			if stats_senjata.has_method("update_stats"):
				stats_senjata.update_stats()
				
			_sinkronkan_ke_tangan_aktif_player()
			
		MenuState.MENU_RARITY:
			if GameManager.total_currency < biaya_nempa_rarity:
				print("❌ Koin tidak cukup!")
				return
				
			var sukses = GameManager.upgrade_weapon_rarity(stats_senjata)
			if sukses:
				GameManager.total_currency -= biaya_nempa_rarity
				_sinkronkan_ke_tangan_aktif_player()

	if GameManager.has_signal("currency_changed"): 
		GameManager.currency_changed.emit(GameManager.total_currency)
	update_tampilan_ui()

func _sinkronkan_ke_tangan_aktif_player() -> void:
	if node_tangan_player == null: return
	
	var indeks_slot = slot_terpilih_forge - 1
	
	if "database_stats" in node_tangan_player and nama_senjata_aktif != "":
		node_tangan_player.database_stats[nama_senjata_aktif] = stats_senjata
	
	if "slot_aktif" in node_tangan_player and node_tangan_player.slot_aktif == indeks_slot:
		if node_tangan_player.has_node("node_senjata_di_tangan"):
			var senjata_node = node_tangan_player.get_node("node_senjata_di_tangan")
			if "stats" in senjata_node:
				senjata_node.stats = stats_senjata
				
		if node_tangan_player.has_method("ganti_senjata"):
			node_tangan_player.ganti_senjata()
		elif node_tangan_player.has_method("_update_weapon_visual"):
			node_tangan_player._update_weapon_visual()

func _on_close_button_pressed() -> void:
	visible = false
	get_tree().paused = false 
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
