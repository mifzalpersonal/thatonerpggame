extends Area3D

@export var speed: float = 30.0
@export var lifetime: float = 2.5 
var dmg : float = 15.0
var direction: Vector3 = Vector3.RIGHT 

@export var explosion_scene: PackedScene
var time_elapsed: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_translate(direction * speed * delta)
	
	time_elapsed += delta
	if time_elapsed >= lifetime:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and (body.name == "Char3" or body.name == "CharacterBody3D" or body.is_in_group("Player")):
		return
		
	print("Panah MENABRAK AKURAT: ", body.name)
	
	# Kasih damage & slow ke badan yang ditabrak[cite: 1, 5]
	if body.has_method("take_damage"):
		body.take_damage(dmg) #[cite: 1, 5]
	if body.has_method("apply_freeze_slow"):
		body.apply_freeze_slow(0.6, 4.0) #[cite: 1, 5]
		
	# FIX OPERAN: Oper si 'body' (si zombie) ke fungsi bawah, bukan Vector3!
	explode_di_target(body)

func explode_di_target(target_body: Node):
	if not explosion_scene:
		queue_free()
		return
		
	var explosion = explosion_scene.instantiate()
	
	# Masukin langsung jadi anak dari si zombie (target_body) biar koordinatnya otomatis lokal!
	target_body.add_child(explosion)
	
	# Karena udah jadi anak zombie, set posisinya ke ZERO biar pas di tengah badan si zombie
	explosion.position = Vector3.ZERO
	
	# Dorong sumbu Z dikit ke depan (menghadap kamera) biar gak tenggelam di dalam sprite zombienya
	explosion.position.z = 0.5 
	
	# Paksa skala visualnya tetep normal 1,1,1
	explosion.scale = Vector3(1.0, 1.0, 1.0)
	
	queue_free()
