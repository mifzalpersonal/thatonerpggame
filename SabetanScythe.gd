extends Area3D

@export var kecepatan : float = 15.0
@export var damage : int = 30
@export var masa_hidup : float = 1.0

var waktu_berjalan : float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$Sprite3D.scale = Vector3(0.5, 0.5, 0.5)

func _physics_process(delta: float) -> void:
	# Maju lurus ke depan berdasarkan arah hadap peluru
	global_translate(-global_transform.basis.z * kecepatan * delta)
	
	# VFX Animasi: Makin maju makin membesar, lalu memudar
	waktu_berjalan += delta
	var skala_baru = 0.5 + (waktu_berjalan * 2.0)
	$Sprite3D.scale = Vector3(skala_baru, skala_baru, skala_baru)
	
	var sisa_umur_persen = 1.0 - (waktu_berjalan / masa_hidup)
	var mat = $Sprite3D.material_override as StandardMaterial3D
	if mat != null:
		mat.albedo_color.a = sisa_umur_persen
		
	if waktu_berjalan >= masa_hidup:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	# Jangan ngelukain diri sendiri (CharacterBody3D player)
	if body is CharacterBody3D: 
		return
		
	# Kalau nabrak musuh yang punya fungsi ambil_damage
	if body.has_method("ambil_damage"):
		body.ambil_damage(damage)
		queue_free()
	else:
		# Kalau nabrak tembok kota temen lu, hancur
		queue_free()
