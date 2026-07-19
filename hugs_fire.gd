# ==============================================================================
# hugs_fire.gd (Sudah Disesuaikan dengan Sistem Sentralisasi Player)
# ==============================================================================
extends Node3D

# --- 🟢 INTEGRASI WEAPON DATA (FORGE SYSTEM) ---
# Variabel ini akan otomatis diisi oleh WeaponManager sesuai kartu .tres yang aktif
@export var stats: WeaponData
# -----------------------------------------------

const SLASH_PROJECTILE_SCENE = preload("res://fire_slash.tscn")
@onready var muzzle: Marker3D = $Muzzle
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# --- VARIABEL COOLDOWN ---
@export var attack_cooldown: float = 0.5
var bisa_serang: bool = true
# ----------------------------------

func _ready() -> void:
	# 🎯 BERSIH: Tidak perlu menyambungkan sinyal item_purchased di sini
	# agar tidak terjadi tabrakan data ganda dengan Player.gd
	pass

# 🟢 FUNGSI UTAMA SERANG (Dipanggil otomatis oleh WeaponManager)
func attack() -> void:
	if not bisa_serang:
		return
		
	if stats == null:
		print("🚨 Peringatan: Senjata ini belum terhubung dengan WeaponData (.tres)!")
		return
		
	# Jalankan rentetan fungsi menyerang
	shoot_slash()
	mainkan_sfx_tebasan()
	mainkan_sfx_tebasan2()
	play_attack_animation()
	mulai_cooldown() # Aktifkan pengunci serang

func play_attack_animation() -> void:
	if anim_player.has_animation("Attack"):
		anim_player.stop() 
		anim_player.play("Attack")

func _process(_delta: float) -> void:
	pass

# 🟢 FUNGSI MENEMBAKKAN SLASHER
func shoot_slash() -> void:
	var slash_instance = SLASH_PROJECTILE_SCENE.instantiate()
	get_tree().root.add_child(slash_instance)
	slash_instance.global_transform = muzzle.global_transform
	
	# Ambil data bonus_damage murni (+50) yang dikirim oleh Player melalui script Tangan
	var damage_toko = 0
	if get_parent() and "shop_bonus_damage" in get_parent():
		damage_toko = get_parent().shop_bonus_damage
		
	# 🔥 GameManager langsung memproses damage akhir (+50 penuh dari toko!)
	GameManager.siapkan_peluru(slash_instance, stats, damage_toko)

# --- FUNGSI UNTUK MENGATUR JEDA ---
func mulai_cooldown() -> void:
	bisa_serang = false # Kunci serangan
	
	# Ambil multiplier cooldown dari Tangan.gd untuk mempercepat serangan (Cincin Waktu)
	var current_cooldown = attack_cooldown
	if get_parent() and "shop_attack_cooldown_multiplier" in get_parent():
		current_cooldown *= get_parent().shop_attack_cooldown_multiplier
		
	# Bikin Timer instan lewat kode dengan batas minimal 0.1 detik biar tidak zero-division
	var timer = get_tree().create_timer(max(0.1, current_cooldown))
	
	# Pas timernya habis (timeout), buka kembali kunci serang
	timer.timeout.connect(func(): bisa_serang = true)

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
		
func mainkan_sfx_tebasan2() -> void:
	var template_sfx = get_node_or_null("SfxSlash2")
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
