extends CharacterBody3D
class_name BaseEnemy

@export var attack_cooldown: float = 1.0

var current_hp: float
var player_node: CharacterBody3D
var can_attack: bool = true

var posisi_patroli: Vector3 = Vector3.ZERO
var waktu_ganti_arah: float = 0.0

var teks_damage_terakhir: Label3D = null

# ==========================================================
# --- SISTEM STATUS RPG (ENUM MANAGEMENT) --- 
# ==========================================================
enum StatusType { NONE, BURN, FREEZE, BLOODY, SHOCK }
var current_status: StatusType = StatusType.NONE

# Konfigurasi Warna Terpusat agar tidak saling tabrakan
const STATUS_COLORS = {
	StatusType.NONE: {
		"body": Color(1.0, 1.0, 1.0),
		"glow": Color(0.0, 0.0, 0.0)
	},
	StatusType.BURN: {
		"body": Color(1.5, 0.5, 0.1),       # Oranye membara
		"glow": Color(1.0, 0.35, 0.0)
	},
	StatusType.FREEZE: {
		"body": Color(0.3, 0.7, 2.0),       # Biru es membeku
		"glow": Color(0.1, 0.5, 1.5)
	},
	StatusType.BLOODY: {
		"body": Color(0.8, 0.05, 0.05),     # Merah darah pekat
		"glow": Color(0.5, 0.0, 0.0)
	},
	StatusType.SHOCK: {
		"body": Color(1.8, 1.8, 0.3),       # Kuning listrik
		"glow": Color(1.0, 1.0, 1.0)
	}
}

# Status Bloody Variables
var is_bloody: bool = false
var bloody_timer: float = 0.0
var bloody_tick_timer: float = 0.0

# Status Burn Variables
var burn_stack: int = 0
var is_burning: bool = false
var burn_timer: float = 0.0
var burn_tick_timer: float = 0.0

# Status Slow/Freeze Variables
var is_slowed: bool = false
var slow_timer: float = 0.0
var slow_multiplier: float = 1.0 
# ==========================================================

# --- AMBIL REFERENSI NODE UI & PRELOAD ---
@onready var hp_bar: ProgressBar = $EnemyUI/HPBar
@onready var status_vfx: AnimatedSprite3D = $StatusVFX 

const DAMAGE_TEXT_3D = preload("res://damage_text.tscn") 

# --- FUNGSI DINAMIS UTK DI-OVERRIDE ANAK ---
func ambil_radius() -> float:
	return 12.0

func ambil_max_hp() -> float:
	return 30.0

func ambil_speed() -> float:
	return 5.0

func _ready() -> void:
	current_hp = ambil_max_hp()
	posisi_patroli = global_position
	player_node = get_node_or_null("/root/Main/CharacterBody3D")
	
	if hp_bar:
		hp_bar.max_value = ambil_max_hp()
		hp_bar.value = current_hp
		
	if status_vfx:
		status_vfx.play("default")
		status_vfx.visible = false

func _physics_process(delta: float) -> void:
	# ========================================================
	# --- LOGIKA MANAGEMENT STATUS (BLOODY & BURN) ---
	# ========================================================
	if is_bloody:
		bloody_timer -= delta
		bloody_tick_timer += delta
		
		if bloody_tick_timer >= 1.0:
			take_damage(15, "bleed")
			print(name, " terkena TICK BLEED BLOODY! Sisa HP: ", current_hp)
			bloody_tick_timer = 0.0 
			
		if bloody_timer <= 0:
			is_bloody = false
			print(name, " efek Bloody selesai.")
			update_active_status_visual()

	if is_burning:
		burn_timer -= delta
		burn_tick_timer += delta
		
		if burn_tick_timer >= 1.0:
			# --- TWEAK KALKULASI TICK BURN BERDASARKAN 3% MAX HP ---
			var tick_damage_persen = ambil_max_hp() * 0.05 # 0.03 = 3% dari Max HP
			var damage_akhir = max(1, int(tick_damage_persen)) # Pastikan minimal damage masuk 1 jika HP kecil
			
			take_damage(damage_akhir, "burn")
			print(name, " terkena TICK BURN (3% Max HP)! Damage masuk: ", damage_akhir, " | Sisa HP: ", current_hp)
			burn_tick_timer = 0.0
			
		if burn_timer <= 0:
			is_burning = false
			burn_stack = 0 
			slow_multiplier = 1.0 
			print(name, " efek Burn selesai.")
			update_active_status_visual()

	if is_slowed:
		slow_timer -= delta
		if slow_timer <= 0:
			is_slowed = false
			slow_multiplier = 1.0
			print(name, " efek Freeze Slow selesai.")
			update_active_status_visual()
	# ========================================================

	if player_node == null: return
		
	var jarak_ke_player = global_position.distance_to(player_node.global_position)
	var batas_radius = ambil_radius()
	var kecepatan_musuh = ambil_speed() * slow_multiplier
	
	# LOGIKA PERGERAKAN
	if jarak_ke_player <= batas_radius:
		var ngejar = player_node.global_position - global_position
		ngejar.y = 0
		if ngejar.length() > 0.1:
			velocity = ngejar.normalized() * kecepatan_musuh
		else:
			velocity = Vector3.ZERO
	else:
		waktu_ganti_arah -= delta
		if waktu_ganti_arah <= 0.0:
			var sudut_acak = randf_range(0, 2 * PI)
			var jarak_acak = randf_range(3.0, 7.0)
			posisi_patroli = global_position + Vector3(cos(sudut_acak) * jarak_acak, 0, sin(sudut_acak) * jarak_acak)
			waktu_ganti_arah = randf_range(2.0, 4.0)
			
		var jarak_ke_titik = global_position.distance_to(posisi_patroli)
		if jarak_ke_titik > 0.5:
			velocity = (posisi_patroli - global_position).normalized() * (kecepatan_musuh * 0.5)
			velocity.y = 0
		else:
			velocity = Vector3.ZERO
			
	move_and_slide()
	
	# LOGIKA ATTACK
	if jarak_ke_player <= batas_radius:
		for i in get_slide_collision_count():
			var collided = get_slide_collision(i).get_collider()
			if collided == player_node and can_attack:
				var health_component = player_node.get_node_or_null("darahEntity")
				if health_component != null:
					health_component.hp -= 1.0
					start_attack_cooldown()

func start_attack_cooldown() -> void:
	can_attack = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# ==========================================================
# --- SISTEM HITUNGAN DAMAGE & CRITICAL HIT ---
# ==========================================================

# Menerima damage_akhir dan status is_crit dari projectile/weapon
func take_damage(amount: int, tipe_damage: String = "normal", is_crit: bool = false) -> void:
	current_hp -= amount
	if hp_bar: 
		hp_bar.value = current_hp
		
	# Oper status is_crit ke visual generator
	spawn_damage_text(amount, tipe_damage, is_crit)
	
	if current_hp <= 0: 
		mati()

func spawn_damage_text(amount: int, tipe_damage: String = "normal", is_crit: bool = false) -> void:
	# 1. JIKA ANGKA DAMAGE SEBELUMNYA MASIH AKTIF (STAKING DAMAGE)
	if is_instance_valid(teks_damage_terakhir):
		var damage_sebelumnya = teks_damage_terakhir.text.to_int()
		teks_damage_terakhir.text = str(damage_sebelumnya + amount)
		
		# Jika crit, perbesar visual akumulasinya secara instan!
		var target_scale = Vector3(2.0, 2.0, 2.0) if is_crit else Vector3(1.4, 1.4, 1.4)
		teks_damage_terakhir.scale = target_scale
		
		var t = create_tween()
		t.tween_property(teks_damage_terakhir, "scale", Vector3(1.0, 1.0, 1.0), 0.1)
		
		var tipe_final = "crit" if is_crit else tipe_damage
		atur_warna_outline_teks(teks_damage_terakhir, tipe_final)
		return 

	# 2. SPAWN ANGKA DAMAGE BARU (FLOATING TEXT)
	if DAMAGE_TEXT_3D:
		var teks_damage = DAMAGE_TEXT_3D.instantiate()
		teks_damage.text = str(amount)
		
		# Kasih offset acak melayang biar dinamis
		var offset_acak = Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), randf_range(-0.1, 0.1))
		teks_damage.global_position = global_position + Vector3(0, 2.3, 0) + offset_acak
		
		# Set visual custom jika crit sebelum masuk tree
		if is_crit:
			teks_damage.scale = Vector3(1.4, 1.4, 1.4) # Skala dasar awal dibesarkan (karena di damage_text diperkecil)
			teks_damage.text += "!"
			atur_warna_outline_teks(teks_damage, "crit")
		else:
			atur_warna_outline_teks(teks_damage, tipe_damage)
			
		get_tree().current_scene.add_child(teks_damage)
		teks_damage_terakhir = teks_damage

func atur_warna_outline_teks(label_node: Label3D, tipe: String) -> void:
	if not label_node: return
	label_node.outline_render_priority = label_node.render_priority + 1
	label_node.outline_size = 14
	
	match tipe:
		"crit":
			label_node.modulate = Color(1.0, 0.1, 0.1)          # Teks dalam warna merah menyala
			label_node.outline_modulate = Color(0.4, 0.0, 0.0)  # Outline merah pekat gelap
		"bleed": 
			label_node.outline_modulate = Color(0.5, 0.0, 0.0)
		"burn": 
			label_node.outline_modulate = Color(1.0, 0.2, 0.0)
		"slow": 
			label_node.outline_modulate = Color(0.0, 0.5, 1.0)
		_: 
			label_node.outline_modulate = Color(0.1, 0.1, 0.1)

func mati() -> void:
	if GameManager.has_method("register_enemy_death"):
		GameManager.register_enemy_death()
	queue_free()

# ==========================================================
# --- VISUAL MODULATE MANAGEMENT (TANPA SHADER & PARTIKEL) ---
# ==========================================================

func apply_shader_status_effect(type: StatusType) -> void:
	current_status = type
	var sprite = get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	if not sprite: return

	var colors = STATUS_COLORS.get(type, {"body": Color(1, 1, 1)})
	var tween = create_tween()
	
	if type == StatusType.BURN:
		# Modulate kedipan flash putih/oranye super terang saat pecah
		tween.tween_property(sprite, "modulate", Color(5.0, 2.0, 0.5), 0.1) 
		# Lalu kembalikan ke warna gosong menetap
		tween.tween_property(sprite, "modulate", colors["body"], 0.2)
	else:
		tween.tween_property(sprite, "modulate", colors["body"], 0.25)

func update_active_status_visual() -> void:
	var sprite = get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	
	if is_burning:
		if current_status != StatusType.BURN:
			apply_shader_status_effect(StatusType.BURN)
		if status_vfx:
			status_vfx.visible = true
			status_vfx.play("Burn3")
	elif is_bloody:
		if current_status != StatusType.BLOODY:
			apply_shader_status_effect(StatusType.BLOODY)
		if status_vfx:
			status_vfx.visible = true
			status_vfx.play("bleed")
	elif is_slowed:
		if current_status != StatusType.FREEZE:
			apply_shader_status_effect(StatusType.FREEZE)
		if status_vfx:
			status_vfx.visible = true
			status_vfx.play("slow")
	else:
		current_status = StatusType.NONE
		if sprite:
			sprite.modulate = Color(1, 1, 1)
		if status_vfx:
			status_vfx.play("default")
			status_vfx.visible = false

# ==========================================================
# --- OVERRIDE TRIGGER GAMEPLAY STATUS ---
# ==========================================================

func apply_freeze_slow(percentage: float, duration: float) -> void:
	is_slowed = true
	slow_timer = duration
	slow_multiplier = 1.0 - percentage
	update_active_status_visual()

func apply_bloody_effect() -> void:
	is_bloody = true
	bloody_timer = 3.0 
	bloody_tick_timer = 0.0
	update_active_status_visual()

# SEKARANG MENERIMA KERUSAKAN/DAMAGE DARI PEDANG PLAYER
func apply_burn_stack(sword_damage: float) -> void:
	if is_burning: return 
		
	burn_stack += 1
	print(name, " terkena tebasan api! Stack: ", burn_stack, "/3")
	
	if status_vfx:
		status_vfx.visible = true
		match burn_stack:
			1: status_vfx.play("Burn1")
			2: status_vfx.play("Burn2")
			3: status_vfx.play("Burn3")
	
	# JIKA MENCAPAI FULL STACK (3 STACK)
	if burn_stack >= 3:
		# RUMUS: Damage Pedang + 5% dari MAX HP Musuh
		var bonus_damage_hp = ambil_max_hp() * 0.05
		var total_burst_damage = sword_damage + bonus_damage_hp
		
		# Berikan damage instan ledakan burn
		take_damage(int(total_burst_damage), "burn")
		print("BURN BURST! Total Damage: ", total_burst_damage, " (Termasuk 5% Max HP: ", bonus_damage_hp, ")")
		
		# Aktifkan kondisi terbakar berkala (Tick Burn) & Slow
		is_burning = true
		burn_timer = 5.0 
		burn_tick_timer = 0.0
		slow_multiplier = 0.5 
		
		# Pemicu kedipan kilatan warna visual
		apply_shader_status_effect(StatusType.BURN)
