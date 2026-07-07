extends CharacterBody3D
class_name BaseEnemy

@export var attack_cooldown: float = 1.0

var current_hp: float
var player_node: CharacterBody3D
var can_attack: bool = true

var posisi_patroli: Vector3 = Vector3.ZERO
var waktu_ganti_arah: float = 0.0

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

func change_enemy_color(new_color: Color) -> void:
	var sprite = get_node_or_null("AnimatedSprite3D")
	if sprite and sprite is AnimatedSprite3D:
		sprite.modulate = new_color

func reset_enemy_color() -> void:
	var sprite = get_node_or_null("AnimatedSprite3D")
	if sprite and sprite is AnimatedSprite3D:
		sprite.modulate = Color(1, 1, 1)
