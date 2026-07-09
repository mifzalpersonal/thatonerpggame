extends CharacterBody3D
class_name BaseEnemy

@export var attack_cooldown: float = 1.0

var current_hp: float
var player_node: CharacterBody3D
var can_attack: bool = true

var posisi_patroli: Vector3 = Vector3.ZERO
var waktu_ganti_arah: float = 0.0

# ==========================================================
# --- ditambahin ijal 	
# --- SISP STATUS RPG BARU (TWEAK) --- 
# ==========================================================
# Status Bloody (Blood Katana)
var is_bloody: bool = false
var bloody_timer: float = 0.0
var bloody_tick_timer: float = 0.0

# Status Burn (Senjata Api)
var burn_stack: int = 0
var is_burning: bool = false
var burn_timer: float = 0.0
var burn_tick_timer: float = 0.0
# ==========================================================


# --- AMBIL REFERENSI NODE UI ---
@onready var hp_bar: ProgressBar = $EnemyUI/HPBar
# -------------------------------

# --- VARIABEL UNTUK STATUS SLOW ---
var is_slowed: bool = false
var slow_timer: float = 0.0
var slow_multiplier: float = 1.0 
# ----------------------------------

# --- FUNGSI DINAMIS UTK DI-OVERRIDE ANAK ---
func ambil_radius() -> float:
	return 12.0

func ambil_max_hp() -> float:
	return 30.0

func ambil_speed() -> float:
	return 5.0
# -------------------------------------------

func _ready() -> void:
	current_hp = ambil_max_hp()
	posisi_patroli = global_position
	player_node = get_node_or_null("/root/Main/CharacterBody3D")
	
	# --- INISIALISASI TAMPILAN HP BAR ---
	if hp_bar:
		hp_bar.max_value = ambil_max_hp()
		hp_bar.value = current_hp
	# ------------------------------------

func _physics_process(delta: float) -> void:
	# ========================================================
	# --- TWEAK LOGIKA MANAGEMENT STATUS (BLOODY & BURN) ---
	# ========================================================
	# 1. Siklus Hitung Mundur Efek Bloody (15 damage tiap 1 detik selama 3 detik)
	if is_bloody:
		bloody_timer -= delta
		bloody_tick_timer += delta
		
		if bloody_tick_timer >= 1.0:
			take_damage(15)
			print(name, " terkena TICK BLEED BLOODY! Sisa HP: ", current_hp)
			bloody_tick_timer = 0.0 
			
		if bloody_timer <= 0:
			is_bloody = false
			print(name, " efek Bloody selesai.")

	# 2. Siklus Hitung Mundur Efek Burn (Total 70 damage dalam 5 detik = 14 damage/detik)
	if is_burning:
		burn_timer -= delta
		burn_tick_timer += delta
		
		if burn_tick_timer >= 1.0:
			take_damage(14)
			print(name, " terkena TICK BURN! Sisa HP: ", current_hp)
			burn_tick_timer = 0.0
			
		if burn_timer <= 0:
			is_burning = false
			burn_stack = 0 # Reset stack setelah efek gosongnya selesai
			if "slow_multiplier" in self:
				slow_multiplier = 1.0 # Kembalikan speed bawaan lu jika pakai multiplier
			reset_enemy_color()
			print(name, " efek Burn selesai.")
	# ========================================================

	# ... SISA KODE BAWAAN LU (NGEJAR PLAYER/PATROLI) BIARKAN UTUH DI BAWAH SINI ...
	
	if is_slowed:
		slow_timer -= delta
		if slow_timer <= 0:
			is_slowed = false
			slow_multiplier = 1.0
			reset_enemy_color()
			print(name, " sudah normal kembali!")

	if player_node == null:
		return
		
	var jarak_ke_player = global_position.distance_to(player_node.global_position)
	var batas_radius = ambil_radius()
	var kecepatan_musuh = ambil_speed() * slow_multiplier
	
	# 1. LOGIKA PERGERAKAN (CHASE VS PATROL)
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
	
	# 2. LOGIKA ATTACK
	if jarak_ke_player <= batas_radius:
		for i in get_slide_collision_count():
			var collided = get_slide_collision(i).get_collider()
			if collided == player_node and can_attack:
				var health_component = player_node.get_node_or_null("darahEntity")
				if health_component != null:
					health_component.hp -= 1.0
					print("Hp lu ngurang, sisa: ", health_component.hp)
					start_attack_cooldown()

func start_attack_cooldown() -> void:
	can_attack = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(amount: int) -> void:
	current_hp -= amount
	print(name, " kena hit! Sisa HP: ", current_hp)
	
	# --- UPDATE VALUE BAR HP SAAT KENA HIT ---
	if hp_bar:
		hp_bar.value = current_hp
	# ----------------------------------------
		
	if current_hp <= 0:
		mati()

func mati() -> void:
	print(name, " mati!")
	queue_free()

# --- FUNGSI EFEK FREEZE/SLOW & WARNA ---
func apply_freeze_slow(percentage: float, duration: float) -> void:
	is_slowed = true
	slow_timer = duration
	slow_multiplier = 1.0 - percentage
	change_enemy_color(Color(0.0, 0.75, 1.0))
	
# --- ditambahin ijal 	
func apply_bloody_effect() -> void:
	is_bloody = true
	bloody_timer = 3.0 # Durasi 3 detik sesuai konsep lu
	bloody_tick_timer = 0.0
	change_enemy_color(Color(0.8, 0.1, 0.1)) # Ubah warna agak merah gelap

# Pemicu Burn Berbasis Stack (Dipanggil oleh Senjata Api)
func apply_burn_stack() -> void:
	if is_burning:
		return # Kalau lagi kebakar, gak bisa numpuk stack baru
		
	burn_stack += 1
	print(name, " terkena peluru api! Stack saat ini: ", burn_stack, "/3")
	
	# Begitu genap 3 kali hit... BOOM! Efek Burn DoT Pecah!
	if burn_stack >= 3:
		is_burning = true
		burn_timer = 5.0 # Durasi terbakar DoT 5 detik
		burn_tick_timer = 0.0
		
		# Set efek slow 50% saat terbakar
		if "slow_multiplier" in self:
			slow_multiplier = 0.5 
		elif "is_slowed" in self:
			is_slowed = true
			
		change_enemy_color(Color(1.0, 0.4, 0.0)) # Berubah warna Oranye Gosong
		print("BOOM! ", name, " GOSONG TERBAKAR & MELAMBAT 50%!")

# --- ditambahin ijal 	


func change_enemy_color(new_color: Color) -> void:
	var sprite = get_node_or_null("AnimatedSprite3D")
	if sprite and sprite is AnimatedSprite3D:
		sprite.modulate = new_color

func reset_enemy_color() -> void:
	var sprite = get_node_or_null("AnimatedSprite3D")
	if sprite and sprite is AnimatedSprite3D:
		sprite.modulate = Color(1, 1, 1)
		
