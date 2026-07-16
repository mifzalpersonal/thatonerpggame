extends Control

# Sisi Latar Belakang (Full Screen)
@onready var preview_pivot: Node3D = $SubViewportContainer/SubViewport/GridMap/WeaponPreviewPivot

# Sisi Kanan Melayang
@onready var weapon_name_label: Label = $PanelKanan/VBoxContainer/WeaponNameLabel
@onready var weapon_stats_label: Label = $PanelKanan/VBoxContainer/WeaponStatsLabel
@onready var cost_label: Label = $PanelKanan/VBoxContainer/CostLabel

# Tombol Utama
@onready var forge_button: Button = $PanelKanan/VBoxContainer/ForgeButton        # Tombol Kiri / Atas
@onready var forge_rarity_button: Button = $PanelKanan/VBoxContainer/ForgeRarityButton # Tombol Kanan / Bawah
@onready var close_button: Button = $PanelKanan/VBoxContainer/CloseButton

# ==========================================
# 📦 VARIABEL DATA & STATE MACHINE UI
# ==========================================
var senjata_aktif: Node3D = null
var stats_senjata: Resource = null 
var biaya_nempa_level: int = 100
var biaya_nempa_rarity: int = 100 # Default di-set 100

enum MenuState { HUB, MENU_LEVEL, MENU_RARITY }
var current_state: MenuState = MenuState.HUB

const RARITY_COLORS = {
	"Common": "#ffffff", "Uncommon": "#1ee655", "Rare": "#00bfff", "Epic": "#b026ff", "Legendary": "#ff8c00"
}

# ==========================================
# ⚙️ SIKLUS UTAMA (LIFECYCLE)
# ==========================================
func _ready() -> void:
	if forge_button and not forge_button.pressed.is_connected(_on_forge_button_pressed):
		forge_button.pressed.connect(_on_forge_button_pressed)
		
	if forge_rarity_button and not forge_rarity_button.pressed.is_connected(_on_forge_rarity_button_pressed):
		forge_rarity_button.pressed.connect(_on_forge_rarity_button_pressed)
	
	if close_button and not close_button.pressed.is_connected(_on_close_button_pressed):
		close_button.pressed.connect(_on_close_button_pressed)
		
	if forge_button: forge_button.mouse_filter = Control.MOUSE_FILTER_STOP
	if forge_rarity_button: forge_rarity_button.mouse_filter = Control.MOUSE_FILTER_STOP
	if close_button: close_button.mouse_filter = Control.MOUSE_FILTER_STOP
		
	visible = false

func _process(delta: float) -> void:
	if preview_pivot and preview_pivot.get_child_count() > 0:
		preview_pivot.rotate_y(delta * 0.6)

# ==========================================
# 🛠️ FUNGSI UTAMA (DIPANGGIL OLEH NPC)
# ==========================================
func set_senjata_yang_akan_ditempa(node_senjata: Node3D) -> void:
	senjata_aktif = node_senjata
	stats_senjata = node_senjata.stats
	
	visible = true
	get_tree().paused = true 
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	current_state = MenuState.HUB
	update_preview_3d_senjata()
	update_tampilan_ui()

# ==========================================
# 🎥 RENDER 3D SENJATA
# ==========================================
func update_preview_3d_senjata() -> void:
	if preview_pivot == null or senjata_aktif == null: return
	for child in preview_pivot.get_children(): child.queue_free()
		
	var scene_senjata = load(senjata_aktif.scene_file_path)
	if scene_senjata:
		var kloning_senjata = scene_senjata.instantiate()
		preview_pivot.add_child(kloning_senjata)
		kloning_senjata.position = Vector3(0.0, -0.5, 0.0) 
		kloning_senjata.rotation = Vector3(0, 0, 0)
		kloning_senjata.scale = Vector3(0.8, 0.8, 0.8)
		kloning_senjata.set_process(false)
		kloning_senjata.set_physics_process(false)

# ==========================================
# 🖥️ CORE LOGIC: DYNAMIC STATE UI RE-RENDER
# ==========================================
func update_tampilan_ui() -> void:
	if stats_senjata == null: return
	
	var nama_rarity = stats_senjata.get_rarity_name()
	weapon_name_label.text = stats_senjata.weapon_name + " (Forge +" + str(stats_senjata.forge_level) + ")\n[" + nama_rarity + "]"
	weapon_name_label.modulate = Color(RARITY_COLORS.get(nama_rarity, "#ffffff"))
	
	var dmg_sekarang = stats_senjata.total_damage
	biaya_nempa_level = (stats_senjata.forge_level + 1) * 100 
	biaya_nempa_rarity = 100 # 🔒 Kunci biaya kasta tetap di 100 Koin

	forge_button.disabled = false
	forge_rarity_button.disabled = false

	match current_state:
		MenuState.HUB:
			weapon_stats_label.text = "Silakan pilih jenis modifikasi senjata yang ingin kamu lakukan di Anvil."
			cost_label.text = "💰 Uangmu: " + str(GameManager.total_currency) + " Koin"
			
			forge_button.text = "▶ Buka Menu Upgrade Level"
			forge_rarity_button.text = "▶ Buka Menu Forge Kasta"
			close_button.text = "Keluar UI Anvil"
			
		MenuState.MENU_LEVEL:
			var dmg_level_berikutnya = dmg_sekarang + 5 
			
			weapon_stats_label.text = (
				"MENU UPGRADE LEVEL\n\n" +
				"• Level Saat Ini: Forge +" + str(stats_senjata.forge_level) + "\n" +
				"• Damage Sekarang: " + str(dmg_sekarang) + " 🔥\n"
			)
			
			if stats_senjata.forge_level >= 24:
				weapon_stats_label.text += "• Prospek Damage: LEVEL MAKSIMAL ⚔️"
				cost_label.text = "💰 Koin Kamu: " + str(GameManager.total_currency)
				
				forge_button.text = "LEVEL SUDAH MAKSIMAL!"
				forge_button.disabled = true
			else:
				weapon_stats_label.text += "• Prospek Damage: → " + str(dmg_level_berikutnya) + " (+5 DMG) ⚔️"
				cost_label.text = "Biaya Upgrade: " + str(biaya_nempa_level) + " Koin\n💰 Koin Kamu: " + str(GameManager.total_currency)
				
				forge_button.text = "🔨 EKSEKUSI UPGRADE LEVEL"
				
			forge_rarity_button.text = "⬅ Kembali ke Menu Utama"
			close_button.text = "Tutup"
			
		MenuState.MENU_RARITY:
			var crit_persen = stats_senjata.crit_chance * 100
			var bonus_crit_kasta = stats_senjata.get_rarity_crit_bonus() * 100
			
			var c_common = stats_senjata.chance_common * 100
			var c_uncommon = stats_senjata.chance_uncommon * 100
			var c_rare = stats_senjata.chance_rare * 100
			var c_epic = stats_senjata.chance_epic * 100
			var c_legendary = stats_senjata.chance_legendary * 100
			
			weapon_stats_label.text = (
				"🎲 ANVIL GACHA KASTA SENJATA 🎲\n\n" +
				"• Kasta Saat Ini: " + nama_rarity + "\n" +
				"• Total Damage: " + str(dmg_sekarang) + " 🔥\n" +
				"• Total Crit Chance: " + str(crit_persen) + "% 🎯 (Bonus Kasta: +" + str(bonus_crit_kasta) + "%)\n\n" +
				"📋 PELUANG GACHA SENJATA INI:\n" +
				"• Common: " + str(c_common) + "% | Uncommon: " + str(c_uncommon) + "%\n" +
				"• Rare: " + str(c_rare) + "% | Epic: " + str(c_epic) + "%\n" +
				"• Legendary: " + str(c_legendary) + "%\n\n" +
				"⚠️ Kasta akan langsung diacak ulang setelah dikocok!"
			)
			cost_label.text = "Biaya Gacha Kasta: " + str(biaya_nempa_rarity) + " Koin\n💰 Koin Kamu: " + str(GameManager.total_currency)
			
			forge_button.text = "🎲 KOCOK KASTA BARU"
			forge_rarity_button.text = "⬅ Kembali ke Menu Utama"
			close_button.text = "Tutup"

# ==========================================
# 🔨 LOGIKA SIGNALS & ACTION BUTTONS
# ==========================================
func _on_forge_button_pressed() -> void:
	match current_state:
		MenuState.HUB:
			current_state = MenuState.MENU_LEVEL
			update_tampilan_ui()
			
		MenuState.MENU_LEVEL:
			if stats_senjata.forge_level >= 24:
				print("❌ Level senjata sudah maksimal!")
				return
				
			if GameManager.total_currency < biaya_nempa_level:
				print("❌ Koin tidak cukup!")
				return
			GameManager.total_currency -= biaya_nempa_level
			stats_senjata.forge_level += 1
			if GameManager.has_signal("currency_changed"): GameManager.currency_changed.emit(GameManager.total_currency)
			update_tampilan_ui()
			
		MenuState.MENU_RARITY:
			if GameManager.total_currency < biaya_nempa_rarity:
				print("❌ Koin tidak cukup!")
				return
			var sukses = GameManager.upgrade_weapon_rarity(stats_senjata)
			if sukses:
				GameManager.total_currency -= biaya_nempa_rarity
				if GameManager.has_signal("currency_changed"): GameManager.currency_changed.emit(GameManager.total_currency)
				update_tampilan_ui()

func _on_forge_rarity_button_pressed() -> void:
	match current_state:
		MenuState.HUB:
			current_state = MenuState.MENU_RARITY
			update_tampilan_ui()
			
		MenuState.MENU_LEVEL, MenuState.MENU_RARITY:
			current_state = MenuState.HUB
			update_tampilan_ui()

func _on_close_button_pressed() -> void:
	visible = false
	get_tree().paused = false 
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
