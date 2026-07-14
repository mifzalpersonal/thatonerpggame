extends BaseSlash

# Semua logika pergerakan, scaling, deteksi player, dan kalkulasi damage toko 
# otomatis diwarisi dan diurus di latar belakang oleh BaseSlash!

func _init() -> void:
	speed = 2.5
	damage = 10
	lifetime = 2.5
	
	# Skala bawaan untuk Slash Nature
	scale_awal = Vector3(5, 5, 5)
	scale_tengah = Vector3(20, 20, 20)
	scale_akhir = Vector3(15, 15, 15)

# Tulis efek mekanik unik Nature (Freeze Slow & 20% Peluang Heal) di sini
func _terapkan_efek_unik(body: Node, _damage_terhitung: float) -> void:
	# 1. Kasih efek slow bawaan (40% slow selama 3 detik) ke musuh
	if body.has_method("apply_freeze_slow"):
		body.apply_freeze_slow(0.4, 3.0)
		print("🌿 [NATURE] Musuh terkena efek Slow!")

	# 2. Peluang 20% Heal Player
	if randf() <= 0.2: # Lolos peluang 20%
		var nodes_player = get_tree().get_nodes_in_group("Player")
		if nodes_player.size() > 0:
			var player = nodes_player[0]
			var health_component = player.get_node_or_null("darahEntity")
			if health_component and "hp" in health_component:
				health_component.hp += 1.0
				print("🌿 [NATURE] Heal sukses! HP bertambah jadi: ", health_component.hp)
