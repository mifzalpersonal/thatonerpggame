extends Area3D

@onready var interaction_label: Label3D = $Label3D
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var idle_timer: Timer = $AnimatedSprite3D/Timer

# Variabel penanda apakah player sedang berada di dekat penjual
var player_di_dekat_toko: bool = false

# --- VARIABEL ANIMASI ACAK ---
# Daftar animasi variasi selain idle utama
var random_idles: Array[String] = ["Flicker", "Sing"]
var is_playing_rare: bool = false

func _ready() -> void:
	# Memastikan merchant TETAP berjalan meskipun game sedang di-pause oleh Toko/Menu
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Hubungkan sinyal area masuk dan keluar
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if interaction_label:
		interaction_label.visible = false
		
	# Hubungkan sinyal Timer secara program (atau lewat editor)
	if idle_timer:
		idle_timer.one_shot = true
		idle_timer.timeout.connect(_on_timer_timeout)
		start_random_timer()

func _process(_delta: float) -> void:
	# Jika player di dekat toko dan menekan tombol E
	if player_di_dekat_toko and Input.is_action_just_pressed("interaction"):
		# Cari ShopUI secara dinamis dan aman di dalam Scene Tree
		var shop = cari_node_shop_ui()
		
		if shop:
			# Cek jika toko sedang tertutup, baru jalankan buka_toko
			if not shop.visible:
				shop.buka_toko()
				if interaction_label:
					interaction_label.visible = false # Sembunyikan prompt E saat toko terbuka
		else:
			print("🚨 MERCHANT EROR: Node 'ShopUI' tidak ditemukan di Scene Tree! Periksa susunan nodemu.")

# --- FUNGSI SEARCH DETEKTIF UNTUK MENEMUKAN SHOPUI ---
func cari_node_shop_ui() -> Node:
	# Coba cari di root langsung (jika ShopUI adalah Autoload/Singleton)
	var shop = get_node_or_null("/root/ShopUI")
	if shop: return shop
	
	# Coba cari di dalam CanvasLayer atau Main Scene secara rekursif
	var root = get_tree().root
	return root.find_child("ShopUI", true, false)

# === DETEKSI PLAYER DEKAT MEJA ===
func _on_body_entered(body: Node3D) -> void:
	# Cek apakah yang mendekat adalah player kamu
	if body.name == "Char3" or body.has_method("switch_hud_slot"):
		# Ambil data toko dulu untuk cek apakah toko lagi terbuka atau tidak
		var shop = cari_node_shop_ui()
		var toko_sedang_buka = shop and shop.visible
		
		player_di_dekat_toko = true
		
		# Hanya munculkan label "Tekan E" jika toko sedang tidak terbuka
		if interaction_label and not toko_sedang_buka:
			interaction_label.visible = true 

func _on_body_exited(body: Node3D) -> void:
	if body.name == "Char3" or body.has_method("switch_hud_slot"):
		player_di_dekat_toko = false
		if interaction_label:
			interaction_label.visible = false # Sembunyikan tulisan saat player menjauh


# === SISTEM ANIMASI ACAK (FLICKER / SING) ===
func start_random_timer() -> void:
	if idle_timer:
		# Set waktu rapat di kisaran 5 detik
		idle_timer.wait_time = randf_range(4.5, 5.5)
		idle_timer.start()

func _on_timer_timeout() -> void:
	if sprite and not is_playing_rare:
		is_playing_rare = true
		
		# Mengacak antara "Flicker" atau "Sing" (Pastikan huruf kapitalnya SAMA PERSIS dengan di editor)
		var picked_anim = random_idles.pick_random()
		sprite.play(picked_anim)
		
		# Tunggu hingga animasi sekali putar ini selesai (Pastikan LOOP matikan di editor!)
		await sprite.animation_finished
		
		is_playing_rare = false
		sprite.play("Idle") # Kembali ke animasi diam utama (Pastikan huruf kapital sesuai editor)
			
	# Mulai ulang timer untuk 5 detik berikutnya
	start_random_timer()
