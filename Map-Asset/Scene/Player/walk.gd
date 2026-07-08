extends CharacterBody3D

@export var speed := 10.0
@onready var anim = $AnimatedSprite3D
@onready var node_tangan = $Tangan

# --- TAMBAHAN SPEED BOOST ---
var current_speed: float = 10.0
var speed_boost_timer: Timer
# -----------------------------

# Menggunakan var biasa (bukan @onready langsung kaku) agar bisa dicari ulang nanti jika scene berpindah
var slot_1_ui = null
var slot_2_ui = null

func _ready() -> void:
	await get_tree().process_frame
	# Coba cari node UI saat awal spawn
	_update_ui_references()
	switch_hud_slot(1)
	
	# --- TAMBAHAN SPEED BOOST ---
	current_speed = speed # Set kecepatan awal agar sama dengan eksport var speed
	
	speed_boost_timer = Timer.new()
	speed_boost_timer.one_shot = true
	speed_boost_timer.timeout.connect(_on_speed_boost_timeout)
	add_child(speed_boost_timer)
	# -----------------------------
	
	set_physics_process(false)

func _physics_process(delta):
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

	# Gerakan (SEKARANG MENGGUNAKAN current_speed)
	velocity = input_dir * current_speed
	move_and_slide()

	# Logika Animasi 4 Arah
	if input_dir == Vector3.ZERO:
		anim.stop()
	else:
		if abs(input_dir.x) > abs(input_dir.z):
			if input_dir.x > 0:
				anim.play("Idle_Left")
				node_tangan.position = Vector3(3.0, -3.0, 1.5)
				node_tangan.rotation_degrees.y = 0
			else:
				anim.play("Idle_Right")
				node_tangan.position = Vector3(-3.0, -3.0, -1.5)
				node_tangan.rotation_degrees.y = -180.0
		else:
			if input_dir.z > 0:
				anim.play("Idle_Up")
				node_tangan.position = Vector3(-1.5, -3.0, 2.5)
				node_tangan.rotation_degrees.y = -90.0
			else:
				anim.play("Walk_Down")
				node_tangan.position = Vector3(1.5, -3.0, -2.5)
				node_tangan.rotation_degrees.y = 90.0

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

# --- FUNGSI TAMBAHAN SPEED BOOST (Dipanggil oleh Item Speed Boost) ---
func apply_speed_boost(multiplier: float, duration: float) -> void:
	# Kalikan base speed dengan pengali dari item (misal 10 * 1.5 = 15)
	current_speed = speed * multiplier
	print("Speed Boost Aktif! Kecepatan sekarang: ", current_speed)
	
	# Mulai timer hitung mundur
	speed_boost_timer.start(duration)

func _on_speed_boost_timeout() -> void:
	# Kembalikan kecepatan ke base speed awal saat timer habis
	current_speed = speed
	print("Speed Boost Habis! Kecepatan kembali normal: ", current_speed)
# ---------------------------------------------------------------------

# Fungsi internal untuk mencari ulang UI jika sewaktu-waktu null
func _update_ui_references():
	if slot_1_ui == null:
		slot_1_ui = get_node_or_null("/root/Main/GUI/ItemContainer/ItemSlot")
	if slot_2_ui == null:
		slot_2_ui = get_node_or_null("/root/Main/GUI/ItemContainer/ItemSlot2")

func switch_hud_slot(slot_number: int) -> void:
	_update_ui_references()
	
	# JIKA DI LOBBY (UI tidak ada), keluar diam-diam tanpa nge-print error panjang lebar
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
