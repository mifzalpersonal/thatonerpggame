extends CharacterBody3D

@export var speed := 10.0
# --- TAMBAHAN STATUS UNTUK POTION ---
@export var max_hp: float = 100.0
var current_hp: float = 100.0
# ------------------------------------

@onready var anim = $AnimatedSprite3D
@onready var node_tangan = $Tangan
@onready var radar_aim = $RadarAim # Referensi Radar Area3D

# --- TAMBAHAN GRAVITASI 3D ---
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
# -----------------------------

# --- TAMBAHAN SPEED BOOST ---
var current_speed: float = 10.0
var speed_boost_timer: Timer
# -----------------------------

# --- TAMBAHAN DAMAGE BOOST ---
var damage_multiplier_active: float = 1.0
var damage_boost_timer: Timer
# ------------------------------

# --- STATUS UTAMA TOKO (SENTRALISASI UNTUK MULTI-WEAPON) ---
var shop_bonus_damage: int = 0
var shop_attack_cooldown_multiplier: float = 1.0
# -----------------------------------------------------------

# Menggunakan var biasa (bukan @onready langsung kaku) agar bisa dicari ulang nanti jika scene berpindah
var slot_1_ui = null
var slot_2_ui = null

func _ready() -> void:
	# Masukkan otomatis ke group "Player" via kode demi keamanan deteksi slash & weapon
	add_to_group("Player")
	
	await get_tree().process_frame
	# Coba cari node UI saat awal spawn
	_update_ui_references()
	switch_hud_slot(1)
	
	# --- INITIALIZATION SPEED BOOST ---
	current_speed = speed 
	speed_boost_timer = Timer.new()
	speed_boost_timer.one_shot = true
	speed_boost_timer.timeout.connect(_on_speed_boost_timeout)
	add_child(speed_boost_timer)
	
	# --- INITIALIZATION DAMAGE BOOST ---
	damage_boost_timer = Timer.new()
	damage_boost_timer.one_shot = true
	damage_boost_timer.timeout.connect(_on_damage_boost_timeout)
	add_child(damage_boost_timer)
	# -----------------------------------
	
	# --- MENGHUBUNGKAN EFEK ITEM DARI GAMEMANAGER ---
	if GameManager.has_signal("item_purchased"):
		GameManager.item_purchased.connect(_on_item_purchased)
	
	# Biarkan true agar physics dan gravitasi bisa berjalan!
	set_physics_process(true)

func _physics_process(delta):
	# 1. LOGIKA GRAVITASI DASAR
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var input_dir = Vector3.ZERO

	# WASD input
	if Input.is_key_pressed(KEY_W):
		input_dir.z += 1 # -Z adalah ATAS/DEPAN
	if Input.is_key_pressed(KEY_S):
		input_dir.z -= 1 # +Z adalah BAWAH/BELAKANG
	if Input.is_key_pressed(KEY_A):
		input_dir.x += 1 # -X adalah KIRI
	if Input.is_key_pressed(KEY_D):
		input_dir.x -= 1 # +X adalah KANAN

	# Normalisasi biar jalan diagonal gak lebih cepat
	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()

	# 2. SIMPAN GERAKAN HORIZONTAL (X & Z)
	var target_velocity = input_dir * current_speed
	velocity.x = target_velocity.x
	velocity.z = target_velocity.z
	
	# 3. APLIKASIKAN FISIKA DAN GRAVITASI
	move_and_slide()

	# ========================================================
	# --- TWEAK LOGIKA AIM ASSIST LOCK ROTATION 360° ---
	# ========================================================
	var target_musuh = ambil_musuh_terdekat()
	
	if target_musuh != null:
		node_tangan.position = Vector3(0.0, 0.0, 0.0)
		
		var posisi_target = target_musuh.global_position
		posisi_target.y = global_position.y 
		
		node_tangan.look_at(posisi_target, Vector3.UP)
		node_tangan.rotate_y(deg_to_rad(90.0)) 
		
		if target_musuh.global_position.x > global_position.x:
			anim.play("Idle_Left")
		else:
			anim.play("Idle_Right")
			
	else:
		# --- LOGIKA ANIMASI 4 ARAH JALAN JIKA RADAR KOSONG ---
		if input_dir == Vector3.ZERO:
			anim.stop()
		else:
			if abs(input_dir.x) > abs(input_dir.z):
				if input_dir.x > 0:
					anim.play("Idle_Left")
					node_tangan.position = Vector3(0.0, 0.0, 1.5)
					node_tangan.rotation_degrees.y = 0
				else:
					anim.play("Idle_Right")
					node_tangan.position = Vector3(0.0, 0.0, -1.5)
					node_tangan.rotation_degrees.y = -180.0
			else:
				if input_dir.z > 0:
					anim.play("Idle_Up")
					node_tangan.position = Vector3(-1.5, 0.0, 0.0)
					node_tangan.rotation_degrees.y = -90.0
				else:
					anim.play("Walk_Down")
					node_tangan.position = Vector3(1.5, 0.0, 0.0)
					node_tangan.rotation_degrees.y = 90.0
	# ========================================================

func _process(delta: float) -> void:
	if has_node("Tangan"):
		var manager_senjata = get_node("Tangan")
		
		if Input.is_action_just_pressed("Item1"):
			switch_hud_slot(1)
			if manager_senjata.has_method("ganti_slot"):
				manager_senjata.ganti_slot(1)
				
		if Input.is_action_just_pressed("Item2"):
			switch_hud_slot(2)
			if manager_senjata.has_method("ganti_slot"):
				manager_senjata.ganti_slot(2)
		
		if Input.is_action_just_pressed("attack"):
			if manager_senjata.senjata_sekarang != "":
				manager_senjata.eksekusi_menyerang()

# --- FUNGSI UTAMA MERESPON PEMBELIAN ITEM DARI TOKO ---
func _on_item_purchased(item_id: String) -> void:
	match item_id:
		"hp_potion":
			current_hp = min(current_hp + 50.0, max_hp)
			print("CHAR3: HP dipulihkan! HP Sekarang: ", current_hp, "/", max_hp)
			
		"speed_boots":
			speed += speed * 0.10
			if speed_boost_timer.is_stopped():
				current_speed = speed
			print("CHAR3: Base Speed bertambah permanen! Base Speed: ", speed)

		"atk_buff":
			shop_bonus_damage += 5
			print("CHAR3: Bonus ATK Toko bertambah permanen! Total: +", shop_bonus_damage)
			
		"atk_speed_buff":
			shop_attack_cooldown_multiplier *= 0.85
			print("CHAR3: Cooldown Serang Toko dipotong! Multiplier saat ini: ", shop_attack_cooldown_multiplier)

# --- FUNGSI SPEED BOOST (Temporary / Dari Power Up Map) ---
func apply_speed_boost(multiplier: float, duration: float) -> void:
	current_speed = speed * multiplier
	print("Speed Boost Aktif! Kecepatan sekarang: ", current_speed)
	speed_boost_timer.start(duration)
	
	# --- INTEGRASI UI STATUS ICON ---
	var buff_ui = get_node_or_null("/root/Main/GUI/BuffBar")
	if buff_ui:
		# Ganti path ini sesuai folder aset icon game kamu
		buff_ui.tambah_status_icon("res://StatusIcon/SpeedUp.png", duration, "temporary_speed")

func _on_speed_boost_timeout() -> void:
	current_speed = speed
	print("Speed Boost Habis! Kecepatan kembali normal: ", current_speed)

# --- FUNGSI DAMAGE BOOST (Temporary / Dari Power Up Map) ---
func apply_damage_boost(multiplier: float, duration: float) -> void:
	damage_multiplier_active = multiplier
	print("Damage Boost Aktif! Pengali damage saat ini: x", damage_multiplier_active)
	damage_boost_timer.start(duration)
	
	# --- INTEGRASI UI STATUS ICON ---
	var buff_ui = get_node_or_null("/root/Main/GUI/BuffBar")
	if buff_ui:
		# Ganti path ini sesuai folder aset icon game kamu
		buff_ui.tambah_status_icon("res://StatusIcon/DamageUp.png", duration, "temporary_damage")

func _on_damage_boost_timeout() -> void:
	damage_multiplier_active = 1.0 
	print("Damage Boost Habis! Damage kembali normal.")

# Fungsi internal untuk mencari ulang UI jika sewaktu-waktu null
func _update_ui_references():
	if slot_1_ui == null:
		slot_1_ui = get_node_or_null("/root/Main/GUI/ItemContainer/ItemSlot")
	if slot_2_ui == null:
		slot_2_ui = get_node_or_null("/root/Main/GUI/ItemContainer/ItemSlot2")

func switch_hud_slot(slot_number: int) -> void:
	_update_ui_references()
	
	if slot_1_ui == null or slot_2_ui == null:
		return
		
	if slot_number == 1:
		slot_1_ui.is_active = true   
		slot_2_ui.is_active = false  
		print("HUD: Slot 1 Aktif")
	elif slot_number == 2:
		slot_1_ui.is_active = false  
		slot_2_ui.is_active = true   
		print("HUD: Slot 2 Aktif")

# --- FUNGSI DETEKSI TARGET ZOMBIE ---
func ambil_musuh_terdekat() -> Node3D:
	if radar_aim == null:
		return null
		
	var daftar_body = radar_aim.get_overlapping_bodies()
	var musuh_terdekat: Node3D = null
	var jarak_terdekat: float = 99999.0
	
	for body in daftar_body:
		if body is CharacterBody3D and body != self and (body.is_in_group("Enemy") or "current_hp" in body):
			var jarak = global_position.distance_to(body.global_position)
			if jarak < jarak_terdekat:
				jarak_terdekat = jarak
				musuh_terdekat = body
				
	return musuh_terdekat
