# ==============================================================================
# katana_weapon.gd (Skrip Senjata Katana)
# ==============================================================================
extends Node3D

# --- 🟢 INTEGRASI WEAPON DATA (FORGE SYSTEM) ---
# Variabel ini akan otomatis diisi oleh WeaponManager sesuai kartu .tres yang aktif
@export var stats: WeaponData
# -----------------------------------------------

const SLASH_PROJECTILE_SCENE = preload("res://KatanaSlash.tscn")
@onready var muzzle: Marker3D = $Muzzle
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# --- TAMBAHAN VARIABEL COOLDOWN KATANA ---
@export var attack_cooldown: float = 0.15 # Sedikit penyesuaian default cooldown katana
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
		mainkan_sfx_tebasan()
		mainkan_sfx_tebasan2()
		anim_player.play("Attack")

# 🟢 _process BERSIH DARI INPUT (Karena diatur terpusat di WeaponManager)
func _process(_delta: float) -> void:
	pass

# 🟢 FUNGSI UTAMA SERANG (Dipanggil otomatis oleh WeaponManager lewat eksekusi_menyerang)
func attack() -> void:
	if not bisa_serang:
		return
		
	if stats == null:
		print("🚨 Peringatan: Katana ini belum terhubung dengan WeaponData (.tres)!")
		return
		
	shoot_slash()
	play_attack_animation()
	mulai_cooldown() # Aktifkan pengunci serang

# --- FUNGSI SPAWN PELURU (MENGGUNAKAN HELPER GAMEMANAGER) ---
func shoot_slash() -> void:
	var slash_instance = SLASH_PROJECTILE_SCENE.instantiate()
	get_tree().root.add_child(slash_instance)
	slash_instance.global_transform = muzzle.global_transform
	
	# Menerapkan multiplier skala visual tebasan jika peluru mendukung scaling
	if "scale" in slash_instance:
		slash_instance.scale *= (slash_scale_multiplier / 10.0)
	
	# 🎯 1. Serahkan perhitungan damage, bonus, dan crit ke GameManager
	GameManager.siapkan_peluru(slash_instance, stats, bonus_damage)
	
	# 🟢 2. Ambil data titipan player yang diset di metadata, lalu oper ke peluru
	if has_meta("pencipta"):
		var node_player = get_meta("pencipta")
		
		# Oper data player tersebut ke dalam peluru slash yang baru lahir
		if slash_instance.has_method("set_pencipta"):
			slash_instance.set_pencipta(node_player)
			print("🎯 KATANA: Berhasil oper Player via Metadata ke peluru tebasan!")

# --- FUNGSI UNTUK MENGATUR JEDA ---
func mulai_cooldown() -> void:
	bisa_serang = false # Kunci serangan
	
	# Bikin Timer instan lewat kode
	var timer = get_tree().create_timer(attack_cooldown)
	
	# Pas timernya habis (timeout), buka kembali kunci serang
	timer.timeout.connect(func(): bisa_serang = true)

# --- FUNGSI MERESPON EFEK ITEM TOKO ---
func _on_item_purchased(item_id: String) -> void:
	match item_id:
		"atk_buff":
			bonus_damage += 5
			print("⚔️ KATANA: Antidote ATK dibeli! Bonus damage Katana: +", bonus_damage)
			
		"atk_speed_buff":
			attack_cooldown *= 0.82 # Katana mendapatkan buff ayunan sedikit lebih cepat (18% lebih cepat)
			attack_cooldown = max(0.04, attack_cooldown) # Batas aman kecepatan tebasan beruntun
			print("⚔️ KATANA: Cincin Waktu dibeli! Cooldown Katana dipercepat menjadi: ", attack_cooldown, " detik")
	
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
