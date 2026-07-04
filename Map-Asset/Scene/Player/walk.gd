extends CharacterBody3D

@export var speed := 50.0
@onready var anim = $AnimatedSprite3D
@onready var node_tangan = $Tangan

@onready var slot_1_ui = get_node_or_null("/root/Main/GUI/ItemContainer/ItemSlot")
@onready var slot_2_ui = get_node_or_null("/root/Main/GUI/ItemContainer/ItemSlot2")

func _ready() -> void:
	await get_tree().process_frame
	switch_hud_slot(1)

func _physics_process(delta):
	var input_dir = Vector3.ZERO

	# WASD input (Sudah diperbaiki arah Z nya)
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

	# Gerakan
	velocity = input_dir * speed
	move_and_slide()

	# Logika Animasi 4 Arah
	if input_dir == Vector3.ZERO:
		# Jika diam, mainkan animasi Idle (atau bisa pakai anim.stop())
		# anim.play("Walk_Down") 
		anim.stop()
	else:
		# Utamakan animasi horizontal jika bergerak diagonal, atau sesuaikan seleramu
		if abs(input_dir.x) > abs(input_dir.z):
			if input_dir.x > 0:
				anim.play("Idle_Right") #aslinya mah kiri jir
				node_tangan.position.x = 3.0
				node_tangan.position.y = -3.0
				node_tangan.position.z = 1.5
				node_tangan.rotation_degrees.y = 0
			else:
				anim.play("Idle_Left") #aslinya mah kanan jir
				node_tangan.position.x = -3.0
				node_tangan.position.y = -3.0
				node_tangan.position.z = -1.5
				node_tangan.rotation_degrees.y = -180.0
		else:
			if input_dir.z > 0:
				anim.play("Idle_Up")
				node_tangan.position.x = -1.5
				node_tangan.position.y = -3.0
				node_tangan.position.z = 2.5 
				node_tangan.rotation_degrees.y = -90.0
			else:
				anim.play("Walk_Down")
				node_tangan.position.x = 1.5
				node_tangan.position.y = -3.0
				node_tangan.position.z = -2.5
				node_tangan.rotation_degrees.y = 90.0

	# Catatan: Baris flip_h di bawah ini dihapus karena kamu sudah punya 
	# animasi "Walk_Left" dan "Walk_Right" terpisah di AnimatedSprite3D.
	
func _process(delta: float) -> void:
		if Input.is_action_just_pressed("Item1"):
			switch_hud_slot(1)
		if Input.is_action_just_pressed("Item2"):
			switch_hud_slot(2)
			
		if Input.is_action_just_pressed("attack"):
			if has_node("Tangan"):
				var manager_senjata = get_node("Tangan")
				if manager_senjata.senjata_sekarang != "":
					manager_senjata.eksekusi_menyerang()
					
					
func switch_hud_slot(slot_number: int) -> void:
	if slot_1_ui == null or slot_2_ui == null:
		print("Waduh, node Slot UI belum ketemu. Cek lagi susunan namanya di Main scene!")
		return
		
	if slot_number == 1:
		slot_1_ui.is_active = true   
		slot_2_ui.is_active = false  
		print("HUD: Slot 1 Aktif")
	elif slot_number == 2:
		slot_1_ui.is_active = false  
		slot_2_ui.is_active = true   
		print("HUD: Slot 2 Aktif")
