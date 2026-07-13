extends Node3D

const SLASH_PROJECTILE_SCENE = preload("res://fire_slash.tscn")
@onready var muzzle: Marker3D = $Muzzle
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# --- TAMBAHAN VARIABEL COOLDOWN ---
# Atur waktu jeda serang (misal 0.3 detik, artinya maksimal 3 CPS)
@export var attack_cooldown: float = 0.5
var bisa_serang: bool = true
# ----------------------------------

# --- VARIABEL BARU: BONUS SUNTIKAN EFEK TOKO ---
var bonus_damage: int = 0
# -----------------------------------------------

func _ready() -> void:
	# Hubungkan senjata ke GameManager agar merespon saat item toko dibeli
	if GameManager.has_signal("item_purchased"):
		GameManager.item_purchased.connect(_on_item_purchased)

func play_attack_animation() -> void:
	if anim_player.has_animation("Attack"):
		anim_player.stop() 
		anim_player.play("Attack")

@export var slash_scale_multiplier: float = 10.0

func _process(_delta: float) -> void:
	# Tambahkan kondisi 'bisa_serang' di sini
	if Input.is_action_just_pressed("attack") and bisa_serang:
		shoot_slash()
		mainkan_sfx_tebasan()
		mainkan_sfx_tebasan2()
		play_attack_animation()
		mulai_cooldown() # Aktifkan pengunci serang

func shoot_slash() -> void:
	var slash_instance = SLASH_PROJECTILE_SCENE.instantiate()
	get_tree().root.add_child(slash_instance)
	slash_instance.global_transform = muzzle.global_transform
	
	# SUNTIKKAN BONUS DAMAGE: Jika senjata punya bonus damage dari toko, tambahkan ke base damagenya peluru
	if bonus_damage > 0 and "damage" in slash_instance:
		slash_instance.damage += bonus_damage
		print("⚔️ WEAPON: Peluru di-spawn dengan tambahan +", bonus_damage, " ATK! Total base damage peluru: ", slash_instance.damage)

# --- FUNGSI UNTUK MENGATUR JEDA ---
func mulai_cooldown() -> void:
	bisa_serang = false # Kunci serangan
	
	# Bikin Timer instan lewat kode (kamu gak perlu nambahin node di editor)
	var timer = get_tree().create_timer(attack_cooldown)
	
	# Pas timernya habis (timeout), panggil fungsi untuk buka kunci serang
	timer.timeout.connect(func(): bisa_serang = true)

# --- FUNGSI MERESPON EFEK ITEM TOKO ---
func _on_item_purchased(item_id: String) -> void:
	match item_id:
		"atk_buff":
			# Tambah base damage senjata secara permanen
			bonus_damage += 5
			print("⚔️ WEAPON: Antidote ATK dibeli! Bonus damage senjata saat ini: +", bonus_damage)
			
		"atk_speed_buff":
			# Potong waktu cooldown sebesar 15% (artinya menyerang 15% lebih cepat)
			attack_cooldown *= 0.85
			# Batasi agar cooldown tidak menyentuh angka 0 atau terlalu minus (gameplay guard)
			attack_cooldown = max(0.1, attack_cooldown)
			print("⚔️ WEAPON: Cincin Waktu dibeli! Cooldown tebasan dipercepat menjadi: ", attack_cooldown, " detik")

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
		
func mainkan_sfx_tebasan2() -> void:
	# 1. Ambil acuan ke node template audio bawaan di scene lu
	var template_sfx = get_node_or_null("SfxSlash2")
	
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
