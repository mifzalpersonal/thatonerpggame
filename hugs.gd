# ==============================================================================
# basic_weapon.gd (Sudah Disesuaikan dengan Sistem Sentralisasi Player)
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

@export var slash_scale_multiplier: float = 10.0

func _ready() -> void:
	# 🎯 BERSIH: Tidak perlu menyambungkan sinyal item_purchased di sini
	# agar tidak terjadi tabrakan data ganda dengan Player.gd
	pass

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
	
	# Ambil multiplier cooldown dari Tangan.gd untuk mempercepat serangan (Cincin Waktu)
	var current_cooldown = attack_cooldown
	if get_parent() and "shop_attack_cooldown_multiplier" in get_parent():
		current_cooldown *= get_parent().shop_attack_cooldown_multiplier
		
	var timer = get_tree().create_timer(max(0.05, current_cooldown))
	timer.timeout.connect(func(): bisa_serang = true)

# --- FUNGSI SPAWN PELURU (MENGGUNAKAN DAMAGE FORGE + OPER PLAYER) ---
func shoot_slash() -> void:
	var slash_instance = SLASH_PROJECTILE_SCENE.instantiate()
	get_tree().root.add_child(slash_instance)
	slash_instance.global_transform = muzzle.global_transform
	
	# Menerapkan multiplier skala visual tebasan jika properti scale tersedia
	if "scale" in slash_instance:
		slash_instance.scale *= (slash_scale_multiplier / 10.0)
	
	# Ambil data bonus_damage murni (+50) yang dikirim oleh Player melalui script Tangan (Parent)
	var damage_toko = 0
	var node_tangan = get_parent()
	if node_tangan != null and "shop_bonus_damage" in node_tangan:
		damage_toko = node_tangan.shop_bonus_damage
	
	# 🎯 1. Serahkan perhitungan damage akhir (+50 penuh dari toko!) ke GameManager
	GameManager.siapkan_peluru(slash_instance, stats, damage_toko)
	
	# --- CARI PLAYER SECARA LANGSUNG VIA PARENT HIERARCHY ---
	# Struktur di scene-mu: Player (Char3) -> Tangan -> Senjata ini
	if node_tangan != null:
		var node_player = node_tangan.get_parent() # Ini mengarah langsung ke Char3
		
		if node_player != null and "damage_multiplier_active" in node_player:
			# Langsung oper tanpa ba-bi-bu lewat fungsi peluru
			if slash_instance.has_method("set_pencipta"):
				slash_instance.set_pencipta(node_player)
				print("🎯 Berhasil oper Player langsung dari hierarchy ke peluru!")
		else:
			print("🚨 Gagal nemu Player di parent! Cek susunan nodemu di scene.")

# --- SFX AUDIO ENGINE ---
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
