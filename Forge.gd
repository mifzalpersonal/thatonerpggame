extends Node3D

@onready var prompt_label: Label3D = $PromptLabel 
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var idle_timer: Timer = $AnimatedSprite3D/Timer

var player_di_dalam_area: bool = false
var player_ref: Node3D = null

# --- VARIABEL ANIMASI ACAK ---
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
	# Cari node UI Forge secara dinamis di Scene Tree
	var forge_ui = get_tree().root.find_child("ForgeUI", true, false)
	if forge_ui == null:
		forge_ui = get_tree().root.find_child("forge_ui", true, false)
		
	if forge_ui:
		print("✅ Node ForgeUI berhasil ditemukan di Scene Tree!")
		
		# Panggil fungsi inisialisasi utama di UI Forge dan oper referensi tubuh player
		if forge_ui.has_method("open_forge_menu"):
			forge_ui.open_forge_menu(player_ref)
			print("🖥️ UI Forge SUKSES TERBUKA DENGAN DATA PLAYER!")
		else:
			# Rencana cadangan jika fungsi tidak sengaja terhapus/berubah nama di UI
			forge_ui.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			print("🚨 WARNING: Fungsi 'open_forge_menu' tidak ketemu di UI, membuka visual saja.")
	else:
		print("🚨 ERROR FATAL: Node bernama 'ForgeUI' atau 'forge_ui' SAMA SEKALI TIDAK ADA di Scene Tree kamu!")

func tutup_menu_forge() -> void:
	var forge_ui = get_tree().root.find_child("ForgeUI", true, false)
	if forge_ui == null:
		forge_ui = get_tree().root.find_child("forge_ui", true, false)
		
	if forge_ui and forge_ui.visible:
		forge_ui.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 

# === ⏱️ SISTEM ANIMASI ACAK FORGE (FLICKER SETIAP ±5 DETIK) ===
func start_random_timer() -> void:
	if idle_timer:
		idle_timer.wait_time = randf_range(4.5, 5.5)
		idle_timer.start()

func _on_timer_timeout() -> void:
	if sprite and not is_playing_rare:
		is_playing_rare = true
		
		var picked_anim = random_idles.pick_random()
		sprite.play(picked_anim)
		
		await sprite.animation_finished
		
		is_playing_rare = false
		sprite.play("Idle")
			
	start_random_timer()
