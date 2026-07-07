extends Area3D

@export var speed: float = 30.0
var direction: Vector3 = Vector3.RIGHT 

# Drag & drop scene Explosion3D.tscn kamu ke variabel ini di Inspector
@export var explosion_scene: PackedScene

func _physics_process(delta: float) -> void:
	# Terbang lurus ke depan sesuai arah bow
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	# Debug print untuk ngecek di Output apakah panah menyentuh collider musuh
	print("Panah menabrak: ", body.name)
	
	# Cek jika menabrak musuh (baik lewat class BaseEnemy atau Group) atau tembok
	if body is BaseEnemy or body.is_in_group("enemy") or body.is_in_group("walls"):
		explode()

func explode():
	if not explosion_scene:
		print("ERROR: Ambil file Explosion3D.tscn lalu drag ke Inspector Arrow!")
		return
		
	var explosion = explosion_scene.instantiate()
	explosion.global_position = self.global_position
	# Paksa sumbu Z ledakan di posisi yang sama agar pas kena musuh
	explosion.global_position.z = self.global_position.z
	
	get_tree().root.add_child(explosion)
	
	# Hapus panah setelah meledak
	queue_free()
