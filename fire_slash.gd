extends Area3D

@export var speed: float = 2.5
@export var damage: int = 70
@export var lifetime: float = 2.5 # Total waktu terbang

@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D

var time_elapsed: float = 0.0

var scale_awal: Vector3 = Vector3(5, 5, 5)   
var scale_tengah: Vector3 = Vector3(20, 20, 20) 
var scale_akhir: Vector3 = Vector3(15, 15, 15)  

# --- TAMBAHAN UNTUK DAMAGE BOOST ---
var pencipta_peluru: Node3D = null

# Fungsi ini nanti dipanggil oleh script Tangan/Senjata saat spawn peluru ini
func set_pencipta(player_node: Node3D):
	pencipta_peluru = player_node
# -----------------------------------

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	scale = scale_awal
	
	if animated_sprite:
		animated_sprite.play("Slash")

func _physics_process(delta: float) -> void:
	global_translate(global_transform.basis.x * speed * delta)
	
	time_elapsed += delta
	var progress: float = time_elapsed / lifetime
	
	if progress >= 1.0:
		queue_free()
		return
		
	if progress < 0.5:
		var t: float = progress / 0.5
		scale = scale_awal.lerp(scale_tengah, t)
	else:
		var t: float = (progress - 0.5) / 0.5
		scale = scale_tengah.lerp(scale_akhir, t)

func _on_body_entered(body: Node) -> void:
	# Abaikan jika menabrak diri sendiri (Player)
	if body is CharacterBody3D and body.name == "Char3": 
		return
		
	if body.has_method("take_damage"):
		# 1. Tentukan base damage awal milik peluru ini
		var damage_akhir: float = float(damage)
	
		# --- AMBIL DATA TOKO & MULTIPLIER DARI PLAYER (CENTRALIZED) ---
		var nodes_player = get_tree().get_nodes_in_group("Player")
		
		if nodes_player.size() > 0:
			var node_player = nodes_player[0] # Ambil Player-nya
			
			# A. Tambahkan bonus damage permanen dari Toko (Antidote ATK) jika ada
			if "shop_bonus_damage" in node_player:
				damage_akhir += node_player.shop_bonus_damage
			
			# B. Kalikan dengan Multiplier Sementara (Power-up Map) jika ada
			if "damage_multiplier_active" in node_player:
				damage_akhir = damage_akhir * node_player.damage_multiplier_active
				
			print("🔥 Peluru ", name, " | Base + Toko: ", (damage + node_player.shop_bonus_damage), " | Final xMultiplier: ", damage_akhir)
		else:
			print("🚨 ERROR: Player belum didaftarkan ke Group 'Player'!")
		
		# --- TWEAK BARU STATUS BURN (DIKIRIM SEBELUM MUSUH MATI) ---
		# Menggunakan 'body' karena itu nama variabel musuh di fungsi ini
		if body.has_method("apply_burn_stack"):
			# Kirim damage_akhir yang sudah dihitung agar burn burst-nya ikut makin sakit!
			body.apply_burn_stack(damage_akhir)

		# 2. Kirim total kalkulasi damage akhir ke musuh
		body.take_damage(int(damage_akhir))
		queue_free()
