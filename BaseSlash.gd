class_name BaseSlash
extends Area3D

@export var speed: float = 2.5
@export var damage: int = 70
@export var lifetime: float = 2.5 # Total waktu terbang

# 🎯 DEKLARASI DI SINI agar bisa di-inject/diakses dari luar (Weapon / GameManager)
var is_critical: bool = false 

@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D

var time_elapsed: float = 0.0

# Nilai default scale, bisa dioverride/diubah di anak-anaknya
var scale_awal: Vector3 = Vector3(5, 5, 5)   
var scale_tengah: Vector3 = Vector3(20, 20, 20) 
var scale_akhir: Vector3 = Vector3(15, 15, 15)  

var pencipta_peluru: Node3D = null

func set_pencipta(player_node: Node3D):
	pencipta_peluru = player_node

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	scale = scale_awal
	
	if animated_sprite and animated_sprite.sprite_frames.has_animation("Slash"):
		animated_sprite.play("Slash")

func _physics_process(delta: float) -> void:
	# Bergerak maju
	global_translate(global_transform.basis.x * speed * delta)
	
	# Efek scaling dinamis
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
	if body is CharacterBody3D and body.name == "Char3": 
		return
		
	if body.has_method("take_damage"):
		var damage_akhir = float(damage) # damage ini nanti sudah diganti oleh WeaponData senjata
		
		# --- CARI PLAYER LEWAT GROUP ---
		var nodes_player = get_tree().get_nodes_in_group("Player")
		if nodes_player.size() > 0:
			var node_player = nodes_player[0]
			
			# Tambahkan bonus toko permanen jika ada
			if "shop_bonus_damage" in node_player:
				damage_akhir += node_player.shop_bonus_damage
			
			# Kalikan dengan multiplier power-up map jika ada
			if "damage_multiplier_active" in node_player:
				damage_akhir = damage_akhir * node_player.damage_multiplier_active
	
		# --- 🎯 PANGGIL EFEK UNIK ELEMEN ---
		_terapkan_efek_unik(body, damage_akhir)
		
		# --- 💥 KIRIM DAMAGE + STATUS CRIT KE ZOMBIE ---
		# Menggunakan 'is_critical' milik class yang sudah disuntik dari Weapon/GameManager
		body.take_damage(int(damage_akhir), "normal", is_critical)
		queue_free()

# Fungsi placeholder agar tidak error saat dipanggil di BaseSlash
func _terapkan_efek_unik(_target: Node, _dmg: float) -> void:
	pass
