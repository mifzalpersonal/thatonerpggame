extends Area3D

@export var speed: float = 2.5
@export var damage: int = 30
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
	# Ganti "Char3" sesuai nama node Player utama kamu jika berbeda
	if body is CharacterBody3D and body.name == "Char3": 
		return
		
	if body.has_method("take_damage"):
		var damage_akhir = float(damage)
		
		# ========================================================
		# --- TWEAK BARU KATANA ---
		# ========================================================
		# 1. Pemicu DoT Bloody di otak musuh
		if body.has_method("apply_bloody_effect"):
			body.apply_bloody_effect()
			
		# 2. Peluang 50% Heal Player
		var nodes_player = get_tree().get_nodes_in_group("Player")
		if nodes_player.size() > 0:
			var player = nodes_player[0]
			if randf() <= 0.5: # Lolos peluang 50%
				var health_component = player.get_node_or_null("darahEntity")
				if health_component and "hp" in health_component:
					health_component.hp += 1.0
					print("🩸 KATANA LIFESTEAL AKTIF! HP lu bertambah jadi: ", health_component.hp)
		# ========================================================
		
		# --- CARI PLAYER LEWAT GROUP (ANTI GAGAL) ---
		# Mencari node pertama yang terdaftar di grup "Player"
		
		if nodes_player.size() > 0:
			var node_player = nodes_player[0] # Ambil Player-nya
			
			if "damage_multiplier_active" in node_player:
				damage_akhir = float(damage) * node_player.damage_multiplier_active
				print("🔥 Peluru ", name, " berhasil dapet multiplier Player lewat Group: ", damage_akhir)
		else:
			print("🚨 ERROR: Player belum didaftarkan ke Group 'Player' di Editor Godot!")
		
		# Kirim damage ke musuh/kardus
		body.take_damage(damage_akhir)
		queue_free()
