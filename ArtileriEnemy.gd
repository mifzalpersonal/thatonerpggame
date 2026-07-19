extends BaseEnemy

# Preload proyektil sesuai path yang lu minta
const PROJECTILE_SCENE = preload("res://enemyAttack.tscn")

@export var attack_range: float = 50.0 # Jarak ideal artileri untuk mulai menembak

# ==========================================================
# --- OVERRIDE STATUS DASAR ARTILERI ---
# ==========================================================
func ambil_max_hp() -> float:
	return 150.0 # Darah lebih tipis dari zombie tapi lebih tebal dari kroco biasa

func ambil_speed() -> float:
	return 4.0 # Kecepatan jalan sedang

func ambil_radius() -> float:
	return 100.0 # Jarak pandang / deteksi player lebih luas dari range tembak

# ==========================================================
# --- LOGIKA FISIKA & SERANGAN ARTILERI ---
# ==========================================================
func _physics_process(delta: float) -> void:
	if player_node == null: return
		
	var jarak_ke_player = global_position.distance_to(player_node.global_position)
	var batas_radius = ambil_radius()
	var kecepatan_musuh = ambil_speed() * slow_multiplier
	
	# --- LOGIKA PERGERAKAN JAUH-DEKAT (KITING) ---
	if jarak_ke_player <= batas_radius:
		var arah_ke_player = player_node.global_position - global_position
		arah_ke_player.y = 0
		
		# Jika player terlalu dekat (kurang dari setengah attack range), artileri mundur (kiting)
		if jarak_ke_player < (attack_range * 0.5):
			velocity = -arah_ke_player.normalized() * kecepatan_musuh
		# Jika masih dalam jarak tembak ideal, diam dan fokus menembak
		elif jarak_ke_player <= attack_range:
			velocity = Vector3.ZERO
		# Jika player di luar attack range tapi masuk radius deteksi, kejar player
		else:
			velocity = arah_ke_player.normalized() * kecepatan_musuh
	else:
		# Logika patroli acak bawaan BaseEnemy jika player tidak terdeteksi
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
	
	# --- LOGIKA TEMBAKAN PROYEKTIL ---
	# Artileri menembak jika player berada di dalam rentang attack_range dan cooldown selesai
	if jarak_ke_player <= attack_range and can_attack:
		tembak_proyektil()
		start_attack_cooldown()

# Fungsi instansiasi proyektil serangan jarak jauh
func tembak_proyektil() -> void:
	if PROJECTILE_SCENE == null:
		push_error("Gagal memuat enemyAttack.tscn!")
		return
		
	print(name, " menembakkan artileri ke arah Player!")
	var peluru = PROJECTILE_SCENE.instantiate()
	
	# Masukkan proyektil ke root scene agar pergerakannya independen dari parent
	get_tree().current_scene.add_child(peluru)
	
	# Set posisi awal peluru sedikit di atas koordinat artileri agar pas di badan
	peluru.global_position = global_position + Vector3(0, 1.5, 0)
	
	# PENTING: Arahkan proyektil ke posisi koordinat Player saat ini
	# Pastikan di script "enemyAttack.gd" milik peluru lu punya fungsi/variabel arah atau target!
	if peluru.has_method("set_direction"):
		var arah_tembak = (player_node.global_position - peluru.global_position).normalized()
		peluru.set_direction(arah_tembak)
	elif "target_position" in peluru:
		peluru.target_position = player_node.global_position
