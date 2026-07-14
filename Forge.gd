extends Node3D

@onready var prompt_label: Label3D = $PromptLabel 

var player_di_dalam_area: bool = false
var player_ref: Node3D = null

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	print("🤖 NPC Forge Siap! Menunggu player mendekat...")

func _unhandled_input(event: InputEvent) -> void:
	if player_di_dalam_area and event.is_action_pressed("interaction"):
		print("⌨️ Tombol interaksi ditekan! Mencoba membuka menu forge...")
		buka_menu_forge()

# --- 🟢 SIGNAL: PLAYER MASUK AREA ---
func _on_interaction_area_body_entered(body: Node3D) -> void:
	print("🔍 Ada objek masuk area NPC: ", body.name)
	
	# Kita buat pengecekan lebih longgar biar pasti ketemu
	if body.is_in_group("Player") or body.name.contains("Char") or body.name.contains("Player"): 
		player_di_dalam_area = true
		player_ref = body
		print("🎯 Player terdeteksi! Menunggu tombol interaksi...")
		
		if prompt_label:
			prompt_label.visible = true

# --- 🔴 SIGNAL: PLAYER KELUAR AREA ---
func _on_interaction_area_body_exited(body: Node3D) -> void:
	if body == player_ref:
		print("🚶 Player pergi menjauh dari NPC.")
		player_di_dalam_area = false
		player_ref = null
		if prompt_label:
			prompt_label.visible = false
		tutup_menu_forge()

# --- 🛠️ FUNGSI BUKA MENU FORGE ---
func buka_menu_forge() -> void:
	# Cari ForgeUI di root game
	var forge_ui = get_tree().root.find_child("ForgeUI", true, false)
	
	if forge_ui == null:
		# Cari alternatif kalau namanya huruf kecil semua
		forge_ui = get_tree().root.find_child("forge_ui", true, false)
		
	if forge_ui:
		print("✅ Node ForgeUI berhasil ditemukan di Scene Tree!")
		var senjata_ditemukan = cari_skrip_senjata_di_player(player_ref)
		
		if senjata_ditemukan:
			if senjata_ditemukan.stats != null:
				if forge_ui.has_method("set_senjata_yang_akan_ditempa"):
					forge_ui.set_senjata_yang_akan_ditempa(senjata_ditemukan)
				
				forge_ui.visible = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				print("🖥️ UI Forge SUKSES TERBUKA!")
			else:
				print("🚨 ERROR: Senjata ketemu, tapi 'stats' (.tres) senjata itu KOSONG!")
		else:
			print("🚨 ERROR: WeaponManager atau Senjata Aktif tidak ketemu di tubuh Player!")
	else:
		print("🚨 ERROR FATAL: Node bernama 'ForgeUI' atau 'forge_ui' SAMA SEKALI TIDAK ADA di Scene Tree kamu!")

func tutup_menu_forge() -> void:
	var forge_ui = get_tree().root.find_child("ForgeUI", true, false)
	if forge_ui == null:
		forge_ui = get_tree().root.find_child("forge_ui", true, false)
		
	if forge_ui and forge_ui.visible:
		forge_ui.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 

# --- 🔍 HELPER CARI SENJATA DI SKRIP FORGE.GD NPC ---
func cari_skrip_senjata_di_player(player: Node3D) -> Node3D:
	if player == null:
		return null
	
	# Mencari node "Tangan" (huruf T besar) di tubuh Player kamu
	var node_tangan = player.find_child("Tangan", true, false)
	
	if node_tangan:
		print("📦 Node 'Tangan' ditemukan pada Player.")
		
		# DISESUAIKAN: Membaca variabel 'node_senjata_di_tangan' dari skripmu!
		if "node_senjata_di_tangan" in node_tangan:
			var senjata = node_tangan.node_senjata_di_tangan
			if senjata != null:
				print("⚔️ Senjata ditemukan di Tangan: ", senjata.name)
				return senjata
			else:
				print("🚨 ERROR: Node 'Tangan' ada, tapi Player lagi gak megang senjata (kosong)!")
		else:
			print("🚨 ERROR: Nama variabel 'node_senjata_di_tangan' tidak cocok dengan skrip di node Tangan!")
	else:
		print("🚨 ERROR: Node bernama 'Tangan' (T besar) tidak ditemukan di tubuh Player!")
		
	return null
