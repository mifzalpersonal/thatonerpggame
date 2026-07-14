extends BaseSlash

# Semua logika pergerakan, scaling, deteksi player, dan kalkulasi damage toko 
# otomatis diwarisi dan diurus di latar belakang oleh BaseSlash!

func _init() -> void:
	speed = 2.5
	damage = 30
	lifetime = 2.5
	
	# Skala bawaan untuk Slash Katana
	scale_awal = Vector3(5, 5, 5)
	scale_tengah = Vector3(20, 20, 20)
	scale_akhir = Vector3(15, 15, 15)

# Tulis efek mekanik unik Katana (Bloody DoT & 50% Peluang Heal) di sini
func _terapkan_efek_unik(body: Node, _damage_terhitung: float) -> void:
	# 1. Pemicu DoT Bloody di otak musuh
	if body.has_method("apply_bloody_effect"):
		body.apply_bloody_effect()
		print("🩸 [KATANA] Musuh terkena status Bloody!")

	# 2. Peluang 50% Heal Player
	if randf() <= 0.5: # Lolos peluang 50%
		var nodes_player = get_tree().get_nodes_in_group("Player")
		if nodes_player.size() > 0:
			var player = nodes_player[0]
			var health_component = player.get_node_or_null("darahEntity")
			if health_component and "hp" in health_component:
				health_component.hp += 1.0
				print("🩸 [KATANA] Lifesteal sukses! HP bertambah jadi: ", health_component.hp)
