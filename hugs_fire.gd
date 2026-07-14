# ==============================================================================
# hugs_fire.gd (Menggunakan Helper GameManager)
# ==============================================================================
extends Node3D

# --- 🟢 INTEGRASI WEAPON DATA (FORGE SYSTEM) ---
# Variabel ini akan otomatis diisi oleh WeaponManager sesuai kartu .tres yang aktif
@export var stats: WeaponData
# -----------------------------------------------

const SLASH_PROJECTILE_SCENE = preload("res://fire_slash.tscn")
@onready var muzzle: Marker3D = $Muzzle
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# --- TAMBAHAN VARIABEL COOLDOWN ---
@export var attack_cooldown: float = 0.5
var bisa_serang: bool = true
# ----------------------------------

# --- VARIABEL BARU: BONUS SUNTIKAN EFEK TOKO ---
var bonus_damage: int = 0
# -----------------------------------------------

func _ready() -> void:
	# Hubungkan senjata ke GameManager agar merespon saat item toko dibeli
	if GameManager.has_signal("item_purchased"):
		GameManager.item_purchased.connect(_on_item_purchased)

# 🟢 FUNGSI UTAMA SERANG (Dipanggil otomatis oleh WeaponManager lewat eksekusi_menyerang)
func attack() -> void:
	if not bisa_serang:
		return
		
	if stats == null:
		print("🚨 Peringatan: Senjata ini belum terhubung dengan WeaponData (.tres)!")
		return
		
	# Jalankan rentetan fungsi menyerangmu
	shoot_slash()
	mainkan_sfx_tebasan()
	mainkan_sfx_tebasan2()
	play_attack_animation()
	mulai_cooldown() # Aktifkan pengunci serang

func play_attack_animation() -> void:
	if anim_player.has_animation("Attack"):
		anim_player.stop() 
		anim_player.play("Attack")

@export var slash_scale_multiplier: float = 10.0

# 🟢 _process SEKARANG BERSIH DARI INPUT DETECT (Karena sudah diatur terpusat)
func _process(_delta: float) -> void:
	pass

# ==============================================================================
# 🎯 PERUBAHAN DI SINI: LEBIH SINGKAT, BERSIH, & MUDAH DITIRU!
# ==============================================================================
func shoot_slash() -> void:
	var slash_instance = SLASH_PROJECTILE_SCENE.instantiate()
	get_tree().root.add_child(slash_instance)
	slash_instance.global_transform = muzzle.global_transform
	
	# 🔥 CUKUP PANGGIL 1 BARIS SAKTI INI:
	# GameManager akan otomatis mengurus: status forge, hitung crit, 
	# menambah bonus toko, lalu langsung menyuntikkannya ke slash_instance!
	GameManager.siapkan_peluru(slash_instance, stats, bonus_damage)


# --- FUNGSI UNTUK MENGATUR JEDA ---
func mulai_cooldown() -> void:
	bisa_serang = false # Kunci serangan
	
	# Bikin Timer instan lewat kode
	var timer = get_tree().create_timer(attack_cooldown)
	
	# Pas timernya habis (timeout), panggil fungsi untuk buka kunci serang
	timer.timeout.connect(func(): bisa_serang = true)

# --- FUNGSI MERESPON EFEK ITEM TOKO ---
func _on_item_purchased(item_id: String) -> void:
	match item_id:
		"atk_buff":
			# Tambah base damage senjata secara permanen
			bonus_damage += 5
			print("⚔️ WEAPON: Antidote ATK dibeli! Bonus damage senjata saat ini: +", bonus_damage)
			
		"atk_speed_buff":
			# Potong waktu cooldown sebesar 15% (artinya menyerang 15% lebih cepat)
			attack_cooldown *= 0.85
			# Batasi agar cooldown tidak menyentuh angka 0 atau terlalu minus (gameplay guard)
			attack_cooldown = max(0.1, attack_cooldown)
			print("⚔️ WEAPON: Cincin Waktu dibeli! Cooldown tebasan dipercepat menjadi: ", attack_cooldown, " detik")

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
