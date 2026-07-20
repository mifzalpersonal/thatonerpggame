extends CharacterBody3D

@export var max_hp: float = 1500.0
@export var movement_speed: float = 4.0
@export var attack_cooldown: float = 3.5 # Jeda antar tembakan hujan proyektil

# 🔥 Pasangkan scene peluru/proyektil artileri yang udah lu benerin kemaren!
@export var projectile_scene: PackedScene 

var current_hp: float
var player_ref: CharacterBody3D = null
var cooldown_timer: float = 0.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D # Pastikan node ini ada di scene BOSS

func _ready() -> void:
	# Ambil base stats bawaan level/wave dari GameManager biar darah boss-nya ikutan scaling
	var stats = GameManager.get_enemy_stats(max_hp, 30.0, movement_speed)
	current_hp = stats["hp"]
	movement_speed = stats["speed"]
	
	print("🚨 THE BOSS LAHIR! Darah Maksimal: ", current_hp)
	
	# Cari keberadaan target (Player) di dalam map dunia game
	var players = get_tree().get_nodes_in_group("Player")
	if not players.is_empty():
		player_ref = players[0] as CharacterBody3D

func _physics_process(delta: float) -> void:
	if player_ref == null or current_hp <= 0:
		return
		
	# --------------------------------------------------------------------------
	# 1. PERILAKU PERGERAKAN: KEJAR PLAYER PAKE NAVIGATION MATRIX
	# --------------------------------------------------------------------------
	nav_agent.target_position = player_ref.global_position
	
	if not nav_agent.is_navigation_finished():
		var next_path_pos = nav_agent.get_next_path_position()
		var current_pos = global_position
		var direction = (next_path_pos - current_pos).normalized()
		
		# Kunci rotasi sumbu Y biar si Boss selalu natap ke arah player dengan gagah
		var look_target = Vector3(player_ref.global_position.x, global_position.y, player_ref.global_position.z)
		if global_position.distance_to(look_target) > 0.1:
			look_at(look_target, Vector3.UP)
			
		velocity = direction * movement_speed
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		
	# --------------------------------------------------------------------------
	# 2. MEKANIK SERANGAN: HUJAN PROYETKIL ARTILERI ACAK
	# --------------------------------------------------------------------------
	if cooldown_timer > 0:
		cooldown_timer -= delta
	else:
		serang_player_pake_artileri()
		cooldown_timer = attack_cooldown

func serang_player_pake_artileri() -> void:
	if projectile_scene == null:
		print("⚠️ Peringatan: Proyektil boss belum di-drag ke Inspector!")
		return
		
	print("💥 BOSS: MERIAM ARTILERI DITEMBAKKAN!")
	
	# Kita buat si boss menembakkan 3 proyektil sekaligus (Spread shot) agar menantang!
	var angles = [-0.2, 0.0, 0.2]
	for offset_angle in angles:
		var peluru = projectile_scene.instantiate()
		get_tree().current_scene.add_child(peluru)
		
		# Posisikan kemunculan peluru agak maju di depan mata si Boss
		var spawn_pos = global_position + (-global_transform.basis.z * 2.0) + Vector3(0, 1.0, 0)
		peluru.global_position = spawn_pos
		
		# Hitung arah tembakan presisi ke arah posisi player saat ini
		var dir_to_player = (player_ref.global_position - global_position).normalized()
		var final_dir = dir_to_player.rotated(Vector3.UP, offset_angle)
		
		# Jika script proyektil lu punya fungsi set_direction, inject langsung ke sini
		if peluru.has_method("set_direction"):
			peluru.set_direction(final_dir)

# Fungsi global saat si Boss menerima tebasan dari pedang tajam lu
# 🔥 SEBELUMNYA DI boss.gd:
# func take_damage(amount: float) -> void:

# 🔥 GANTI JADI INI (Biar bisa nampung 3 argumen dari BaseSlash):
func take_damage(amount: float, type: String = "normal", critical: bool = false) -> void:
	current_hp -= amount
	print("💥 BOSS TERLUKA! Sisa HP: ", current_hp)
	
	# Lu juga bisa manfaatin ini buat spawn teks damage di atas kepala boss nanti
	if has_method("spawn_damage_text"):
		call("spawn_damage_text")
	
	if current_hp <= 0:
		print("💀 SANG BOSS UTAMA TELAH TUMBANG!")
		queue_free() # Memicu tree_exited untuk membuka portal akhir level[cite: 1]
