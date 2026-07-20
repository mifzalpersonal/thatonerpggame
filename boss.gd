extends CharacterBody3D

@export var max_hp: float = 10000.0
@export var movement_speed: float = 4.0

# Jarak ideal si Boss Range untuk berdiri aman
@export var jarak_aman_toko: float = 8.0

# Variable pembantu mekanik kiting & meteor
var dash_count: int = 0
var dash_delay_timer: float = 0.0
var target_dash_position: Vector3 = Vector3.ZERO
var attack_cooldown: float = 0.0
# 🔥 FIXED: Mendeklarasikan kembali state_timer agar bisa dipakai di semua fungsi state!
var state_timer: float = 0.0

# 🎯 SCENE PROYETKIL (Seret enemyAttack.tscn ke sini)
@export var projectile_scene: PackedScene 

# Status State Machine si Boss Range
enum BossState { CHASE_RANGE, DASH_BACK, STORM_ATTACK }
var current_state = BossState.CHASE_RANGE

var current_hp: float
var player_ref: CharacterBody3D = null

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	var stats = GameManager.get_enemy_stats(max_hp, 30.0, movement_speed)
	current_hp = stats["hp"]
	movement_speed = stats["speed"]
	
	print("🚨 THE RANGE BOSS LAHIR! HP: ", current_hp)
	
	var players = get_tree().get_nodes_in_group("Player")
	if not players.is_empty():
		player_ref = players[0] as CharacterBody3D
		
	# Otomatis nyalain health bar pas lahir
	get_tree().call_group("BossUI", "aktifkan_health_bar", self)
	
	# 🔥 ABA-ABA AWAL: Kasih cooldown 2.5 detik pas baru lahir!
	# Selama timer ini jalan, si boss gak bakal langsung nyerang/ngedash, ngasih lu waktu buat ambil posisi.
	attack_cooldown = 2.5

func _physics_process(delta: float) -> void:
	if player_ref == null or current_hp <= 0:
		return
		
	# Boss range SELALU menatap tajam player di sumbu Y dalam keadaan apa pun
	var look_target = Vector3(player_ref.global_position.x, global_position.y, player_ref.global_position.z)
	if global_position.distance_to(look_target) > 0.1:
		look_at(look_target, Vector3.UP)
		
	# Kurangi cooldown global
	if attack_cooldown > 0:
		attack_cooldown -= delta
		
	# 🔥 MEKANIK REVOLUSI: KONDISI LOW HEALTH (HP < 40%)
	# Jika darah kritis, dia bakal konstan nge-drop meteor tambahan dari langit secara berkala!
	if (current_hp / max_hp <= 0.4) and int(Time.get_ticks_msec() / 100) % 8 == 0:
		_spawn_meteor_dadakan()

	# --- STATE MACHINE CONTROL ---
	match current_state:
		BossState.CHASE_RANGE:
			_logika_chase_range(delta)
		BossState.DASH_BACK:
			_logika_dash_back(delta)
		BossState.STORM_ATTACK:
			_logika_storm(delta)

# ==================== 1. MODE TINGGAL DI JARAK AMAN (KITING) ====================
func _logika_chase_range(delta: float):
	var jarak_ke_player = global_position.distance_to(player_ref.global_position)
	
	# 🔥 PENGAMAN 1: Kalo player terlalu deket (< 5 meter), KONTAN DASH KABUR KE BELAKANG!
	if jarak_ke_player < 5.0 and attack_cooldown < 2.5:
		_siapkan_dash_ke_belakang()
		_ganti_state(BossState.DASH_BACK, 0.4)
		return
		
	# Logika pergerakan AI agar melingkar / menjaga jarak aman 8 meter
	nav_agent.target_position = player_ref.global_position
	if not nav_agent.is_navigation_finished():
		var next_path_pos = nav_agent.get_next_path_position()
		var direction = (next_path_pos - global_position).normalized()
		
		# Jika terlalu dekat, mundur biasa. Jika pas, diam/sidestep. Jika kejauhan, maju dikit.
		if jarak_ke_player < jarak_aman_toko:
			velocity = -direction * movement_speed # Mundur pelan
		else:
			velocity = direction * (movement_speed * 0.5) # Maju santai
			
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		
	# 🔥 LOGIKA SERANGAN BERDASARKAN JARAK:
	if attack_cooldown <= 0:
		if jarak_ke_player > 12.0:
			# Player kejauhan? Hajar pakai badai meteor!
			_ganti_state(BossState.STORM_ATTACK, 3.0)
		else:
			# Jarak standar? Tembak 5 meriam artileri biasa
			serang_player_pake_artileri()
			attack_cooldown = 2.5

# ==================== 2. MODE KITING DASH (KABUR KE BELAKANG) ====================
func _siapkan_dash_ke_belakang():
	if player_ref != null:
		var arah_dari_player = (global_position - player_ref.global_position).normalized()
		# Tentukan titik 7 meter di belakang posisi boss saat ini
		target_dash_position = global_position + (arah_dari_player * 7.0)
		dash_delay_timer = 0.1 # Jeda kedip singkat sebelum loncat mundur
		print("💨 BOSS: 'Jangan sentuh gua!' *Dash ke belakang*")

func _logika_dash_back(delta: float):
	if dash_delay_timer > 0:
		dash_delay_timer -= delta
		velocity = Vector3.ZERO
		return
		
	state_timer -= delta
	
	# Melesat mundur dengan kecepatan 10x lipat
	var arah_mundur = (target_dash_position - global_position).normalized()
	velocity = arah_mundur * (movement_speed * 10.0)
	move_and_slide()
	
	if state_timer <= 0 or global_position.distance_to(target_dash_position) < 1.0:
		# Selesai kabur, langsung kasih serangan balasan (artileri) biar player kaget
		serang_player_pake_artileri()
		attack_cooldown = 2.0
		_ganti_state(BossState.CHASE_RANGE, 0.0)

# ==================== 3. MODE BADAI METEOR AKTIF ====================
func _logika_storm(delta: float):
	state_timer -= delta
	velocity = Vector3.ZERO # Diam di tempat mengumpulkan energi kosmik
	
	# Hujan meteor deras setiap 0.25 detik
	if int(state_timer * 100) % 25 == 0:
		_spawn_meteor_dadakan()
			
	if state_timer <= 0:
		_ganti_state(BossState.CHASE_RANGE, 2.0)

# ==================== FUNGSI PEMBANTU SPAWN METEOR ====================
func _spawn_meteor_dadakan():
	if projectile_scene == null or player_ref == null: return
	
	var peluru = projectile_scene.instantiate()
	get_tree().current_scene.add_child(peluru)
	
	# Drop meteor acak di sekeliling area posisi lari player
	var target_acak = player_ref.global_position + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
	peluru.global_position = target_acak + Vector3(0, 10.0, 0) # Jatuh dari langit tinggi
	
	if peluru.has_method("set_direction"):
		peluru.set_direction(Vector3.DOWN)

func serang_player_pake_artileri() -> void:
	if projectile_scene == null: return
	
	var angles = [-0.4, -0.2, 0.0, 0.2, 0.4]
	for offset_angle in angles:
		var peluru = projectile_scene.instantiate()
		get_tree().current_scene.add_child(peluru)
		
		var spawn_pos = global_position + (-global_transform.basis.z * 1.5) + Vector3(0, 1.0, 0)
		peluru.global_position = spawn_pos
		
		var dir_to_player = (player_ref.global_position - global_position).normalized()
		var final_dir = dir_to_player.rotated(Vector3.UP, offset_angle)
		
		if peluru.has_method("set_direction"):
			peluru.set_direction(final_dir)

func _ganti_state(state_baru: BossState, durasi: float):
	current_state = state_baru
	state_timer = durasi
	if state_baru == BossState.STORM_ATTACK:
		print("🔮 BOSS: LU KEJAUHAN! RASAKAN HUJAN METEOR!")
	elif state_baru == BossState.DASH_BACK:
		print("⚡ BOSS: KITING! EVADING CLOSE RANGE!")

# ==================== DITERIMA DARI BASESLASH LU ====================
func take_damage(amount: float, type: String = "normal", critical: bool = false) -> void:
	current_hp -= amount
	print("💥 BOSS RANGE TERLUKA! Sisa HP: ", current_hp)
	
	# Failsafe: Jika pas digebuk dia dalam keadaan biasa, paksa pemicu dash mundur instan!
	if current_state == BossState.CHASE_RANGE:
		_siapkan_dash_ke_belakang()
		_ganti_state(BossState.DASH_BACK, 0.4)
	
	if current_hp <= 0:
		print("💀 SANG BOSS RANGE TELAH TUMBANG!")
		queue_free()
