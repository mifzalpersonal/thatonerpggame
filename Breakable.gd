extends StaticBody3D

# --- EXPORT VARIABLES (Bisa diatur dari Inspector) ---
@export_category("Loot Table (Total harus 100)")
@export var chance_empty: int = 50       # Peluang kosong
@export var chance_temporary: int = 35   # Peluang power-up sementara
@export var chance_permanent: int = 15   # Peluang power-up permanen

@export_category("Prefabs Item")
@export var item_temporary_prefab: PackedScene
@export var item_permanent_prefab: PackedScene

@export_category("Object Health")
@export var max_health: float = 10.0
var current_health: float

func _ready():
	current_health = max_health

# Fungsi ini dipanggil saat objek menerima damage dari player/peluru
func take_damage(amount: float):
	current_health -= amount
	if current_health <= 0:
		destroy_object()

func destroy_object():
	# 1. Jalankan fungsi penentu drop item
	roll_loot()
	
	# 2. EFEK VISUAL HANCUR
	# Sembunyikan mesh kardus utama dan matikan collision agar tidak mengganggu player lagi
	$blockbench_export.hide() 
	$CollisionShape3D.disabled = true
	
	# Picu partikel ledakan kardus
	if has_node("GPUParticles3D"):
		$GPUParticles3D.emitting = true
		# Tunggu selama 1 detik (sampai partikel selesai jatuh) sebelum menghapus objek sepenuhnya
		await get_tree().create_timer(1.0).timeout
	
	# 3. Hancurkan objek dari game
	queue_free()

func roll_loot():
	# Ambil angka acak dari 0 sampai 99
	var roll = randi() % 100
	
	# Cek hasil roll berdasarkan bobot persentase
	if roll < chance_empty:
		print("Zonk! Tidak ada item.")
		return # Keluar dari fungsi, tidak spawn apa-apa
		
	elif roll < (chance_empty + chance_temporary):
		# Jika roll di antara 50 sampai 84
		spawn_item(item_temporary_prefab)
		print("Spawn: Power Up Sementara!")
		
	else:
		# Jika roll di antara 85 sampai 99
		spawn_item(item_permanent_prefab)
		print("Spawn: Power Up Permanen!")

func spawn_item(item_prefab: PackedScene):
	if item_prefab == null:
		return
		
	# Instansiasi item baru
	var item_instance = item_prefab.instantiate()
	
	# Masukkan item ke dalam level (parent dari objek ini)
	get_parent().add_child(item_instance)
	
	# Pindahkan posisi item ke posisi objek yang hancur saat ini
	item_instance.global_position = self.global_position
