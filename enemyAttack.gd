extends Area3D

@export var speed: float = 15.0
@export var damage: float = 1.0
@export var max_lifetime: float = 5.0 # Detik maksimal sebelum peluru ilang sendiri

var velocity: Vector3 = Vector3.ZERO
@onready var bullet_animation: AnimatedSprite3D = $AnimatedSprite3D

func _ready() -> void:
	# Hubungkan signal tabrakan secara internal lewat kode
	body_entered.connect(_on_body_entered)
	bullet_animation.play("new_animation")
	
	# Pengaman: Hancurkan peluru otomatis kalau gak kena apa-apa setelah beberapa detik
	await get_tree().create_timer(max_lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# Gerakkan proyektil lurus sesuai arah velocity yang udah disuntik
	global_position += velocity * speed * delta

# Fungsi krusial yang dipanggil oleh ArtileriEnemy.gd tadi buat nentuin arah terbang
func set_direction(direction: Vector3) -> void:
	velocity = direction.normalized()
	
	# Opsional: Bikin peluru menghadap ke arah terbangnya biar gak kaku
	if velocity.length() > 0.001:
		look_at(global_position + velocity, Vector3.UP)

# Logika mendeteksi tabrakan
func _on_body_entered(body: Node) -> void:
	# Cek apakah yang ditabrak adalah player lu
	# (Sesuaikan dengan nama node player lu, di script base enemy lu pakenya CharacterBody3D)
	if body is CharacterBody3D and body.name == "CharacterBody3D":
		var health_component = body.get_node_or_null("darahEntity")
		if health_component != null:
			health_component.hp -= damage
			print("💥 PROYEKTIL: Player terkena tembakan artileri! Damage: ", damage)
		
		# Hancurkan peluru setelah berhasil mengenai target
		queue_free()
	
	# Opsional: Hancurkan peluru kalau menabrak tembok/gridmap lingkungan
	elif body is GridMap or body.name.begins_with("StaticBody"):
		queue_free()
