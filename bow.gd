# ==============================================================================
# bow_weapon.gd (Skrip Busur - Terintegrasi Sistem Sentralisasi & Crit)
# ==============================================================================
extends Node3D

# --- 🟢 INTEGRASI WEAPON DATA (FORGE SYSTEM) ---
@export var stats: WeaponData
# -----------------------------------------------

const ARROW_PROJECTILE_SCENE = preload("res://arrow.tscn")
@onready var muzzle: Marker3D = $Muzzle

# --- TAMBAHAN VARIABEL COOLDOWN ---
@export var attack_cooldown: float = 0.5
var bisa_serang: bool = true
# ----------------------------------

func _process(_delta: float) -> void:
	pass

func attack() -> void:
	if not bisa_serang:
		return
		
	if stats == null:
		print("🚨 Peringatan: Busur ini belum terhubung dengan WeaponData (.tres)!")
		return
		
	shoot_arrow()
	mainkan_sfx_tebasan()
	mulai_cooldown()

# --- FUNGSI SPAWN PANAH (MENGGUNAKAN DAMAGE FORGE + CRIT + DIRECTION) ---
func shoot_arrow() -> void:
	if ARROW_PROJECTILE_SCENE == null:
		return
		
	var arrow_instance = ARROW_PROJECTILE_SCENE.instantiate()
	
	# Taruh di root yang sama biar posisi global 3D-nya sinkron
	get_tree().root.add_child(arrow_instance)
	
	# Samakan posisi dan arah rotasi global panah dengan Muzzle senjata
	arrow_instance.global_transform = muzzle.global_transform
	
	# 🟢 Ambil data bonus_damage murni dari toko yang dikelola Player via script Tangan (Parent)
	var damage_toko = 0
	if get_parent() and "shop_bonus_damage" in get_parent():
		damage_toko = get_parent().shop_bonus_damage
	
	# 🎯 1. KALKULASI CRITICAL DAMAGE DARI WEAPON DATA
	var hasil_serangan: Dictionary = stats.hitung_damage_output()
	
	# Tambahkan damage dasar + damage toko baru kemudian dikalikan crit jika beruntung,
	# atau gunakan damage_toko sebagai flat tambahan di akhir sesuai mekanik base game kamu.
	# Di sini kita tambahkan langsung ke damage akhir agar dihitung bersih:
	var damage_akhir: float = hasil_serangan["damage"] + damage_toko
	var apakah_crit: bool = hasil_serangan["is_critical"]
	
	# Suntikkan damage akhir hasil kalkulasi ke anak panah
	if "damage" in arrow_instance:
		arrow_instance.damage = damage_akhir
		
		if "is_critical" in arrow_instance:
			arrow_instance.is_critical = apakah_crit
			
		if apakah_crit:
			print("💥 CRITICAL SHOT! ", stats.weapon_name, " mendaratkan Crit + Buff Toko sebesar: ", damage_akhir)
		else:
			print("⚔️ WEAPON: ", stats.weapon_name, " menembakkan Arrow biasa + Buff Toko! Damage: ", damage_akhir)
	
	# 🟢 2. Oper data player dari metadata ke anak panah jika peluru membutuhkannya
	if has_meta("pencipta"):
		var node_player = get_meta("pencipta")
		if arrow_instance.has_method("set_pencipta"):
			arrow_instance.set_pencipta(node_player)
	
	# Kasih tahu arah terbang panah
	if "direction" in arrow_instance:
		arrow_instance.direction = muzzle.global_transform.basis.x.normalized()

# --- FUNGSI UNTUK MENGATUR JEDA ---
func mulai_cooldown() -> void:
	bisa_serang = false
	
	# Ambil multiplier cooldown dari Tangan.gd untuk mempercepat durasi reload panah
	var current_cooldown = attack_cooldown
	if get_parent() and "shop_attack_cooldown_multiplier" in get_parent():
		current_cooldown *= get_parent().shop_attack_cooldown_multiplier
		
	# Menggunakan await timer dengan batas aman minimal 0.05 detik
	await get_tree().create_timer(max(0.05, current_cooldown)).timeout
	bisa_serang = true

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
