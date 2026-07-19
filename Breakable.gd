extends StaticBody3D

@export_category("Loot Table (Total Harus 100)")
@export var chance_empty: int = 40       # Peluang tidak keluar apa-apa
@export var chance_temporary: int = 40   # Peluang keluar item sementara (Speed/Damage)
@export var chance_permanent: int = 20   # Peluang keluar item permanen (Heal/MaxHP)

@export_category("Prefabs Item Temporary")
@export var item_speed_boost: PackedScene
@export var item_damage_boost: PackedScene

@export_category("Prefabs Item Permanent")
@export var item_heal: PackedScene
@export var item_max_hp_upgrade: PackedScene # (Atau item permanen ke-2 kamu)

@export_category("Object Health")
@export var max_health: float = 10.0
var current_health: float

func _ready():
	current_health = max_health

# 🎯 PERUBAHAN DI SINI: Tambahkan parameter opsional "_is_critical: bool = false"
# Agar fungsi ini bisa dipanggil dengan 1 argumen ATAU 2 argumen sekaligus tanpa bikin crash.
# Ganti fungsi take_damage yang lama dengan versi ini:
func take_damage(amount: float, _type: String = "normal", _is_critical: bool = false) -> void:
	current_health -= amount
	if current_health <= 0:
		destroy_object()


func destroy_object():
	# 1. Jalankan fungsi penentu drop item
	roll_loot()
	
	# 2. EFEK VISUAL HANCUR
	if has_node("blockbench_export"):
		$blockbench_export.hide() 
	
	var collision = get_node_or_null("CollisionShape3D")
	if collision:
		collision.disabled = true
	
	# Picu partikel ledakan kardus
	if has_node("GPUParticles3D"):
		$GPUParticles3D.emitting = true
		await get_tree().create_timer(1.0).timeout
	
	# 3. Hancurkan objek dari game
	queue_free()

func roll_loot():
	# Ambil angka acak dari 0 sampai 99
	var roll = randi() % 100
	
	# Ambil total bobot agar kalkulasinya dinamis dan akurat seberapapun kamu set di Inspector
	if roll < chance_empty:
		print("Zonk! Tidak ada item.")
		return
		
	elif roll < (chance_empty + chance_temporary):
		# --- JIKA MENDAPATKAN TEMPORARY (Acak lagi 50:50 antara Speed atau Damage) ---
		var sub_roll = randi() % 2
		if sub_roll == 0:
			spawn_item(item_speed_boost)
			print("Spawn Temporary: Speed Boost!")
		else:
			spawn_item(item_damage_boost)
			print("Spawn Temporary: Damage Boost!")
			
	else:
		# --- JIKA MENDAPATKAN PERMANENT (Acak lagi 50:50 antara Heal atau Permanent ke-2) ---
		var sub_roll = randi() % 2
		if sub_roll == 0:
			spawn_item(item_heal)
			print("Spawn Permanent: Heal Jantung!")
		else:
			spawn_item(item_max_hp_upgrade)
			print("Spawn Permanent: Item Permanen 2!")

func spawn_item(item_prefab: PackedScene):
	if item_prefab == null:
		print("Peringatan: Prefab item belum dimasukkan di Inspector!")
		return
		
	var item_instance = item_prefab.instantiate()
	get_parent().add_child(item_instance)
	item_instance.global_position = self.global_position
