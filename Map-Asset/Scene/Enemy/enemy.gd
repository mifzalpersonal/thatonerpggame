extends CharacterBody3D

@export var speed = 3.0
@export var attack_cooldown = 1.0 # Musuh cuma bisa nyerang tiap 1 detik
@onready var musuh = $AnimatedSprite3D

var player_node : CharacterBody3D
var can_attack: bool = true # Status apakah musuh boleh nyerang

func _ready() -> void:
	player_node = get_node_or_null("/root/Main/CharacterBody3D")

func _physics_process(delta: float) -> void: # Lebih stabil untuk pergerakan fisik dibanding _process
	if player_node != null:
		var ngejar = player_node.global_position - global_position
		ngejar.y = 0 # Biar musuh ga terbang/ambles ke tanah kalau player lompat
		ngejar = ngejar.normalized()
		velocity = ngejar * speed
		move_and_slide()
		
		for i in get_slide_collision_count():
			var collided = get_slide_collision(i).get_collider()
			
			if collided == player_node and can_attack:
				var health_component = player_node.get_node_or_null("darahEntity")
				if health_component != null:
					# Kurangi HP Player
					health_component.hp -= 1.0 # Kurangi 1 jantung (atau 0.5 sesuai seleramu)
					print("Hp lu ngurang, sisa: ", health_component.hp, " bang")
					
					# Mulai cooldown serangan
					start_attack_cooldown()

# Fungsi untuk mengatur jeda serangan musuh
func start_attack_cooldown() -> void:
	can_attack = false
	# Bikin timer instan lewat kode selama 1 detik
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
