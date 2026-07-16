extends Node3D

@onready var prompt_label: Label3D = $PromptLabel 
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var idle_timer: Timer = $AnimatedSprite3D/Timer

var player_di_dalam_area: bool = false
var player_ref: Node3D = null

# --- VARIABEL ANIMASI ACAK ---
# Hanya berisi "Flicker" (Pastikan huruf kapitalnya SAMA dengan di editor)
var random_idles: Array[String] = ["Flicker"]
var is_playing_rare: bool = false

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	print("🤖 NPC Forge Siap! Menunggu player mendekat...")
	
	# Hubungkan sinyal Timer secara otomatis & mulai timer
	if idle_timer:
		idle_timer.one_shot = true
		idle_timer.timeout.connect(_on_timer_timeout)
		start_random_timer()

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
	var forge_ui = get_tree().root.find_child("ForgeUI", true, false)
	
	if forge_ui == null:
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
	
	var node_tangan = player.find_child("Tangan", true, false)
	
	if node_tangan:
		print("📦 Node 'Tangan' ditemukan pada Player.")
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


# === ⏱️ SISTEM ANIMASI ACAK FORGE (FLICKER SETIAP ±5 DETIK) ===
func start_random_timer() -> void:
	if idle_timer:
		# Timer disetel rapat di sekitar 5 detik (4.5 sampai 5.5 detik)
		idle_timer.wait_time = randf_range(4.5, 5.5)
		idle_timer.start()

func _on_timer_timeout() -> void:
	if sprite and not is_playing_rare:
		is_playing_rare = true
		
		# Memainkan animasi Flicker
		var picked_anim = random_idles.pick_random()
		sprite.play(picked_anim)
		
		# Tunggu hingga kedipan selesai (Loop Flicker harus mati di editor)
		await sprite.animation_finished
		
		is_playing_rare = false
		sprite.play("Idle") # Kembali ke animasi Idle utama yang looping
			
	# Ulangi lagi timernya untuk 5 detik ke depan
	start_random_timer()
