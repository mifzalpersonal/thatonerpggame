extends RigidBody3D

@export var nama_senjata : String = "Katana Terkutuk"

# Properti kelangkaan dan forge level yang akan diisi secara acak saat spawn
var rarity : String = "Common" 
var forge_level : int = 0

# --- 🎰 SISTEM PERSENTASE CHANCE RARITY ---
const CHANCE_RARITY = {
	"common": 50,
	"uncommon": 25,
	"rare": 15,
	"epic": 7,
	"legendary": 3
}

# --- 🎲 SISTEM CHANCE FORGE LEVEL ---
const CHANCE_FORGE = {
	0: 70,
	1: 20,
	2: 8,
	3: 2
}

const WARNA_RARITY = {
	"common": Color(0.8, 0.8, 0.8),
	"uncommon": Color(0.4, 0.8, 0.4),
	"rare": Color(0.2, 0.5, 1.0),
	"epic": Color(0.6, 0.2, 0.9),
	"legendary": Color(1.0, 0.6, 0.0)
}

const MODEL_SENJATA = {
	"hugs": "res://hugs.tscn",
	"hugs_fire": "res://hugs_fire.tscn",
	"katana": "res://Katana.tscn",
	"sword_slim": "res://sword_slim.tscn",
	"sword_slim_nature": "res://sword_slim_nature.tscn",
	"bow": "res://bow.tscn"
}

var player_di_area : CharacterBody3D = null
var total_waktu : float = 0.0

@onready var model_container: Node3D = $AmbilArea/ModelContainer
@onready var ambil_area: Area3D = $AmbilArea

func _ready() -> void:
	tentukan_rarity_acak()
	tentukan_forge_acak()
	
	if ambil_area:
		if ambil_area.body_entered.is_connected(_on_body_entered):
			ambil_area.body_entered.disconnect(_on_body_entered)
		if ambil_area.body_exited.is_connected(_on_body_exited):
			ambil_area.body_exited.disconnect(_on_body_exited)
			
		ambil_area.body_entered.connect(_on_body_entered)
		ambil_area.body_exited.connect(_on_body_exited)
	
	freeze = true
	freeze_mode = FREEZE_MODE_STATIC
	
	tampilkan_model_senjata()
	update_label_senjata()

# ==============================================================================
# 🎲 FUNGSI PENENTU ACAK (PROBABILITAS)
# ==============================================================================
func tentukan_rarity_acak() -> void:
	var roll = randi() % 100
	var hitung_bobot = 0
	
	for kasta in CHANCE_RARITY:
		hitung_bobot += CHANCE_RARITY[kasta]
		if roll < hitung_bobot:
			rarity = kasta
			return 

func tentukan_forge_acak() -> void:
	var roll = randi() % 100
	var hitung_bobot = 0
	
	for lvl in CHANCE_FORGE:
		hitung_bobot += CHANCE_FORGE[lvl]
		if roll < hitung_bobot:
			forge_level = lvl
			return

# ==============================================================================
# 🛠️ LOGIKA VISUAL & UPDATE LABEL
# ==============================================================================
func tampilkan_model_senjata() -> void:
	if not model_container:
		return
		
	for child in model_container.get_children():
		child.queue_free()
		
	var nama_bersih = nama_senjata.split(" [")[0].strip_edges()
	var key_model = nama_bersih.to_lower()
	
	if "katana" in key_model: key_model = "katana"
	elif "bow" in key_model or "busur" in key_model: key_model = "bow"
	elif "fire" in key_model: key_model = "hugs_fire"
	elif "nature" in key_model: key_model = "sword_slim_nature"
	elif "hugs" in key_model: key_model = "hugs"
	
	if MODEL_SENJATA.has(key_model):
		var path_model = MODEL_SENJATA[key_model]
		var resource_model = load(path_model)
		
		if resource_model:
			var instance_model = resource_model.instantiate()
			if instance_model:
				model_container.add_child(instance_model)
				matikan_collision_internal(instance_model)
				
				# Posisi X diatur ke -0.90
				instance_model.position = Vector3(-0.90, 0.0, 0.0)
	else:
		push_error("Model tidak ditemukan untuk key: " + key_model)

func update_label_senjata() -> void:
	var label = get_node_or_null("InfoLabel")
	if not label:
		label = Label3D.new()
		label.name = "InfoLabel"
		add_child(label)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		
	# Posisi Y dinaikkan agar teks menggantung pas di atas model
	label.position = Vector3(0, 1.2, 0) 
	
	# Booster ukuran teks agar besar dan tetap tajam di ruang 3D
	label.font_size = 48
	label.pixel_size = 0.015
	
	var kasta_text = rarity.to_upper()
	var nama_bersih = nama_senjata.split(" [")[0].strip_edges()
	
	label.text = nama_bersih + " [" + kasta_text + "]\nForge: +" + str(forge_level)
	
	if WARNA_RARITY.has(rarity.to_lower()):
		label.modulate = WARNA_RARITY[rarity.to_lower()]
	else:
		label.modulate = Color(1, 1, 1)

# ==============================================================================
# 🎮 INTERAKSI PLAYER & PENGAMBILAN
# ==============================================================================
func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_node("Tangan"):
		var tangan = body.get_node("Tangan")
		
		if "slot_senjata" in tangan:
			var slot_aktif = tangan.slot_aktif
			
			# Hanya mengecek dan mengambil otomatis ke slot aktif
			if tangan.slot_senjata[slot_aktif] == "":
				suntik_data_ke_resource_tangan(tangan, nama_senjata, rarity, forge_level)
				
				if tangan.has_method("ambil_senjata"):
					tangan.ambil_senjata(nama_senjata)
				queue_free()
			else:
				player_di_area = body
				print("Slot aktif penuh! Tekan 'E' untuk menukar senjata di tangan.")

func _on_body_exited(body: Node3D) -> void:
	if body == player_di_area:
		player_di_area = null

func _process(delta: float) -> void:
	if model_container:
		total_waktu += delta
		model_container.position.y = sin(total_waktu * 3.0) * 0.15
		
	if player_di_area != null and Input.is_action_just_pressed("interaction"):
		eksekusi_tukar_senjata()

func eksekusi_tukar_senjata() -> void:
	if player_di_area == null or not is_instance_valid(player_di_area):
		return
		
	var tangan = player_di_area.get_node_or_null("Tangan")
	if tangan == null or not "slot_senjata" in tangan:
		print("🚨 WEAPON DROP: Node Tangan tidak valid!")
		return
	
	if ambil_area:
		ambil_area.monitoring = false 
	
	var senjata_lama_nama = tangan.slot_senjata[tangan.slot_aktif]
	var senjata_lama_rarity = "common"
	var senjata_lama_forge = 0
	
	if "database_stats" in tangan and tangan.database_stats.has(senjata_lama_nama):
		var res_lama = tangan.database_stats[senjata_lama_nama]
		if res_lama != null:
			senjata_lama_forge = res_lama.forge_level
			if res_lama.has_method("get_rarity_name"):
				senjata_lama_rarity = res_lama.get_rarity_name().to_lower()

	tangan.slot_senjata[tangan.slot_aktif] = nama_senjata
	
	suntik_data_ke_resource_tangan(tangan, nama_senjata, rarity, forge_level)
		
	if tangan.has_method("pasang_visual_senjata"):
		tangan.pasang_visual_senjata(nama_senjata)
	
	nama_senjata = senjata_lama_nama
	rarity = senjata_lama_rarity
	forge_level = senjata_lama_forge
	
	var arah_depan = Vector3.FORWARD
	if player_di_area and is_instance_valid(player_di_area):
		arah_depan = -player_di_area.global_transform.basis.z.normalized()
		global_position = player_di_area.global_position + (arah_depan * 1.5) + Vector3(0, 0.2, 0)
	
	tampilkan_model_senjata()
	update_label_senjata()
	
	print("🔄 SWAP BERHASIL! Di tanah sekarang: ", nama_senjata, " [", rarity, "] (+", forge_level, ")")
	
	await get_tree().create_timer(0.5).timeout
	if ambil_area:
		await get_tree().process_frame
		ambil_area.monitoring = true
	
	player_di_area = null
	if ambil_area:
		for body in ambil_area.get_overlapping_bodies():
			if body is CharacterBody3D:
				player_di_area = body

# --- 🏷️ FUNGSI HELPER UNTUK MENULIS KE RESOURCE PLAYER ---
func suntik_data_ke_resource_tangan(tangan_node: Node, nama_brg: String, kasta_baru: String, level_baru: int) -> void:
	var nama_bersih = nama_brg.split(" [")[0].strip_edges()
	
	if "database_stats" in tangan_node and tangan_node.database_stats.has(nama_bersih):
		var res_data = tangan_node.database_stats[nama_bersih]
		if res_data != null:
			res_data.forge_level = level_baru
			
			match kasta_baru.to_lower():
				"common": res_data.current_rarity = 0
				"uncommon": res_data.current_rarity = 1
				"rare": res_data.current_rarity = 2
				"epic": res_data.current_rarity = 3
				"legendary": res_data.current_rarity = 4
			print("🎯 WEAPONDROP: Berhasil meng-update Resource .tres milik ", nama_bersih, " ke +", level_baru)

func matikan_collision_internal(node: Node) -> void:
	if node is CollisionShape3D or node is CollisionObject3D:
		if node is CollisionShape3D:
			node.disabled = true
		if node is CollisionObject3D:
			node.process_mode = PROCESS_MODE_DISABLED
	for child in node.get_children():
		matikan_collision_internal(child)
