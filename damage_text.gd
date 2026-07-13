extends Label3D

func _ready() -> void:
	# Untuk attack speed kencang, perkecil font size dasar atau perkecil scale awalnya
	scale = Vector3(0.7, 0.7, 0.7) # Dibuat lebih kecil dari default agar tidak menutupi layar
	
	# Lempar dengan sudut melingkar penuh (360 derajat) secara acak eksplosif
	var sudut = randf_range(0, 2 * PI)
	var kekuatan_lempar = randf_range(1.0, 2.0)
	
	var lempar_x = cos(sudut) * kekuatan_lempar
	var lempar_z = sin(sudut) * kekuatan_lempar
	var tinggi_lambungan = randf_range(1.5, 2.5) # Melambung lebih tinggi
	
	var target_kiri_kanan = global_position + Vector3(lempar_x, -0.5, lempar_z)
	var target_puncak_atas = global_position + Vector3(lempar_x / 2.0, tinggi_lambungan, lempar_z / 2.0)
	
	# Jalankan tween seperti biasa (pake durasi lebih cepat, misal 0.35 detik saja biar cepat hilang)
	var gerak_tween = create_tween().set_parallel(true)
	gerak_tween.tween_property(self, "global_position:x", target_kiri_kanan.x, 0.35)
	gerak_tween.tween_property(self, "global_position:z", target_kiri_kanan.z, 0.35)
	
	gerak_tween.tween_property(self, "global_position:y", target_puncak_atas.y, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	gerak_tween.chain().tween_property(self, "global_position:y", target_kiri_kanan.y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.35).set_delay(0.1)
	
	get_tree().create_timer(0.35).timeout.connect(queue_free)
