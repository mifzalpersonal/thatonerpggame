extends Node3D

const SLASH_PROJECTILE_SCENE = preload("res://BasicSlash.tscn")
@onready var muzzle: Marker3D = $Muzzle
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# --- TAMBAHAN VARIABEL COOLDOWN ---
@export var attack_cooldown: float = 0.5
var bisa_serang: bool = true
# ----------------------------------

func play_attack_animation() -> void:
	if anim_player.has_animation("Attack"):
		anim_player.stop() 
		anim_player.play("Attack")

@export var slash_scale_multiplier: float = 10.0

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("attack") and bisa_serang:
		shoot_slash()
		play_attack_animation()
		mainkan_sfx_tebasan()
		mulai_cooldown()

func mulai_cooldown() -> void:
	bisa_serang = false
	var timer = get_tree().create_timer(attack_cooldown)
	timer.timeout.connect(func(): bisa_serang = true)

# --- FUNGSI SPAWN PELURU (SUDAH DIPERBAIKI UNTUK DAMAGE BOOST) ---
func shoot_slash() -> void:
	var slash_instance = SLASH_PROJECTILE_SCENE.instantiate()
	get_tree().root.add_child(slash_instance)
	slash_instance.global_transform = muzzle.global_transform
	
	# --- CARI PLAYER SECARA LANGSUNG VIA PARENT HIERARCHY ---
	# Struktur di scene-mu: Player (Char3) -> Tangan -> Senjata ini
	var node_tangan = get_parent()
	if node_tangan != null:
		var node_player = node_tangan.get_parent() # Ini mengarah langsung ke Char3
		
		if node_player != null and "damage_multiplier_active" in node_player:
			# Langsung oper tanpa ba-bi-bu lewat fungsi peluru
			if slash_instance.has_method("set_pencipta"):
				slash_instance.set_pencipta(node_player)
				print("🎯 Berhasil oper Player langsung dari hierarchy ke peluru!")
		else:
			print("🚨 Gagal nemu Player di parent! Cek susunan nodemu di scene.")
			
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
