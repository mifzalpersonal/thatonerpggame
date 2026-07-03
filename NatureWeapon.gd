extends Node3D

const SLASH_PROJECTILE_SCENE = preload("res://nature_slash.tscn")
@onready var muzzle: Marker3D = $Muzzle
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# --- TAMBAHAN VARIABEL COOLDOWN ---
# Atur waktu jeda serang (misal 0.3 detik, artinya maksimal 3 CPS)
@export var attack_cooldown: float = 0.1

var bisa_serang: bool = true
# ----------------------------------

func play_attack_animation() -> void:
	if anim_player.has_animation("Attack"):
		anim_player.stop() 
		anim_player.play("Attack")

@export var slash_scale_multiplier: float = 10.0

func _process(_delta: float) -> void:
	# Tambahkan kondisi 'bisa_serang' di sini
	if Input.is_action_just_pressed("attack") and bisa_serang:
		shoot_slash()
		play_attack_animation()
		mulai_cooldown() # Aktifkan pengunci serang

func shoot_slash() -> void:
	var slash_instance = SLASH_PROJECTILE_SCENE.instantiate()
	get_tree().root.add_child(slash_instance)
	slash_instance.global_transform = muzzle.global_transform

# --- FUNGSI UNTUK MENGATUR JEDA ---
func mulai_cooldown() -> void:
	bisa_serang = false # Kunci serangan
	
	# Bikin Timer instan lewat kode (kamu gak perlu nambahin node di editor)
	var timer = get_tree().create_timer(attack_cooldown)
	
	# Pas timernya habis (timeout), panggil fungsi untuk buka kunci serang
	timer.timeout.connect(func(): bisa_serang = true)
