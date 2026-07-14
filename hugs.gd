# ==============================================================================
# basic_weapon.gd (Skrip Senjata Kedua - Basic Weapon)
# ==============================================================================
extends Node3D

# --- 🟢 INTEGRASI WEAPON DATA (FORGE SYSTEM) ---
# Variabel ini akan otomatis diisi oleh WeaponManager sesuai kartu .tres yang aktif
@export var stats: WeaponData
# -----------------------------------------------

const SLASH_PROJECTILE_SCENE = preload("res://BasicSlash.tscn")
@onready var muzzle: Marker3D = $Muzzle
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# --- TAMBAHAN VARIABEL COOLDOWN ---
@export var attack_cooldown: float = 0.5
var bisa_serang: bool = true
# ----------------------------------

# --- VARIABEL BARU: BONUS SUNTIKAN EFEK TOKO ---
var bonus_damage: int = 0
# -----------------------------------------------

@export var slash_scale_multiplier: float = 10.0

func _ready() -> void:
	# Hubungkan senjata ke GameManager agar merespon saat item toko dibeli
	if GameManager.has_signal("item_purchased"):
		GameManager.item_purchased.connect(_on_item_purchased)

func play_attack_animation() -> void:
	if anim_player.has_animation("Attack"):
		anim_player.stop() 
		anim_player.play("Attack")

# 🟢 _process SEKARANG BERSIH DARI INPUT (Karena diatur terpusat di WeaponManager)
func _process(_delta: float) -> void:
	pass

# 🟢 FUNGSI UTAMA SERANG (Dipanggil otomatis oleh WeaponManager lewat eksekusi_menyerang)
func attack() -> void:
	if not bisa_serang:
		return
		
	if stats == null:
		print("🚨 Peringatan: Senjata ini belum terhubung dengan WeaponData (.tres)!")
		return
		
	shoot_slash()
	play_attack_animation()
	mainkan_sfx_tebasan()
	mulai_cooldown()

func mulai_cooldown() -> void:
	bisa_serang = false
	var timer = get_tree().create_timer(attack_cooldown)
	timer.timeout.connect(func(): bisa_serang = true)

# --- FUNGSI SPAWN PELURU (MENGGUNAKAN DAMAGE FORGE + OPER PLAYER) ---
func shoot_slash() -> void:
	var slash_instance = SLASH_PROJECTILE_SCENE.instantiate()
	get_tree().root.add_child(slash_instance)
	slash_instance.global_transform = muzzle.global_transform
	
	# Menerapkan multiplier skala visual tebasan jika properti scale tersedia
	if "scale" in slash_instance:
		slash_instance.scale *= (slash_scale_multiplier / 10.0)
	
	# 🎯 1. Serahkan perhitungan damage, bonus toko, dan crit ke GameManager
	GameManager.siapkan_peluru(slash_instance, stats, bonus_damage)
	
	# --- CARI PLAYER SECARA LANGSUNG VIA PARENT HIERARCHY ---
	# Struktur di scene-mu: Player (Char3) -> Tangan -> Senjata ini
	var node_tangan = get_parent()
	if node_tangan != null:
		var node_player = node_tangan.get_parent() # Ini mengarah langsung ke Char3
		
		if node_player != null and "damage_multiplier_active" in node_player:
			# Langsung oper tanpa ba-bi-bu lewat fungsi peluru
			if slash_instance.has_method("set_pencipta"):
				slash_instance.set_pencipta(node_player)
				print("🎯 Berhasil oper Player langsung dari hierarchy ke peluru!")
		else:
			print("🚨 Gagal nemu Player di parent! Cek susunan nodemu di scene.")

# --- FUNGSI MERESPON EFEK ITEM TOKO ---
func _on_item_purchased(item_id: String) -> void:
	match item_id:
		"atk_buff":
			bonus_damage += 5
			print("⚔️ BASIC WEAPON: Antidote ATK dibeli! Bonus damage: +", bonus_damage)
			
		"atk_speed_buff":
			attack_cooldown *= 0.85
			attack_cooldown = max(0.05, attack_cooldown) # Batas aman cooldown
			print("⚔️ BASIC WEAPON: Cincin Waktu dibeli! Cooldown dipercepat menjadi: ", attack_cooldown, " detik")

func mainkan_sfx_tebasan() -> void:
	var template_sfx = get_node_or_null("SfxSlash")
	
	if template_sfx != null and template_sfx.stream != null:
		var sfx_baru = AudioStreamPlayer3D.new()
		
		sfx_baru.stream = template_sfx.stream
		sfx_baru.volume_db = template_sfx.volume_db
		sfx_baru.max_distance = template_sfx.max_distance
		sfx_baru.bus = template_sfx.bus
		sfx_baru.global_transform = global_transform
		sfx_baru.pitch_scale = randf_range(0.95, 1.05)
		
		get_tree().root.add_child(sfx_baru)
		sfx_baru.play()
		sfx_baru.finished.connect(func(): sfx_baru.queue_free())
