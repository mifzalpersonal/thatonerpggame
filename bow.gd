extends Node3D

const ARROW_PROJECTILE_SCENE = preload("res://arrow.tscn")
@onready var muzzle: Marker3D = $Muzzle

@export var attack_cooldown: float = 0.5
var bisa_serang: bool = true

func _process(_delta: float) -> void:
	# REPLIKASI SINKRONISASI PEDANG: 
	# Biarkan 'walk.gd' yang muter tangan, busur cuma fokus ngecek action attack!
	if Input.is_action_just_pressed("attack") and bisa_serang:
		shoot_arrow()
		mainkan_sfx_tebasan()
		mulai_cooldown()

func shoot_arrow() -> void:
	if ARROW_PROJECTILE_SCENE == null:
		return
		
	var arrow_instance = ARROW_PROJECTILE_SCENE.instantiate()
	
	# KLONING PEDANG: Taruh di root yang sama biar posisi global 3D-nya sinkron!
	get_tree().root.add_child(arrow_instance)
	
	# Samakan posisi dan arah rotasi global panah dengan Muzzle senjata lu
	arrow_instance.global_transform = muzzle.global_transform
	
	# KASIH TAHU ARROW: Terbanglah ke depan sesuai arah sumbu X global si Muzzle!
	if "direction" in arrow_instance:
		arrow_instance.direction = muzzle.global_transform.basis.x.normalized()

func mulai_cooldown() -> void:
	bisa_serang = false
	await get_tree().create_timer(attack_cooldown).timeout
	bisa_serang = true

func mainkan_sfx_tebasan() -> void:
	# 1. Ambil acuan ke node template audio bawaan di scene lu
	var template_sfx = get_node_or_null("SfxSlash")
	
	if template_sfx != null and template_sfx.stream != null:
		# 2. Bikin node audio baru secara instan di memori
		var sfx_baru = AudioStreamPlayer3D.new()
		
		# 3. Copy isi file suara dan settingan dari template lu
		sfx_baru.stream = template_sfx.stream
		sfx_baru.volume_db = template_sfx.volume_db
		sfx_baru.max_distance = template_sfx.max_distance
		sfx_baru.bus = template_sfx.bus # Biar ikut settingan audio bus lu kalau ada
		
		# 4. Samakan posisi koordinatnya dengan senjata/muzzle lu biar tetep 3D posisional
		sfx_baru.global_transform = global_transform
		
		# Kasih sedikit random pitch biar suaranya dinamis pas dispam
		sfx_baru.pitch_scale = randf_range(0.95, 1.05)
		
		# 5. Masukkan node audio baru ini ke dalam Map/Dunia game
		get_tree().root.add_child(sfx_baru)
		
		# 6. Mainkan suaranya!
		sfx_baru.play()
		
		# 7. KUNCI STACKING: Begitu durasi suaranya habis, hapus nodenya dari memori biar gak bikin lag
		sfx_baru.finished.connect(func(): sfx_baru.queue_free())
