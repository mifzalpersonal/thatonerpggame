extends PanelContainer

@onready var wave_label: Label = $Margin/Layout/WaveLabel
@onready var wave_bar: ProgressBar = $Margin/Layout/WaveBar

func _ready() -> void:
	visible = false 
	# 1. Pastikan batas maksimal progress bar sesuai dengan MAX_WAVES dari GameManager
	if "MAX_WAVES" in GameManager:
		wave_bar.max_value = GameManager.MAX_WAVES
	else:
		wave_bar.max_value = 3.0 # Fallback jika data tidak terbaca
		
	# 2. Ambil data kondisi awal wave saat ini
	update_wave_ui()
	
	# 3. Hubungkan sinyal perubahan level jika sewaktu-waktu level/wave berganti secara global
	if GameManager.has_signal("level_changed"):
		GameManager.level_changed.connect(update_wave_ui)

## Fungsi utama untuk memperbarui tampilan teks dan bar progress secara real-time
func update_wave_ui() -> void:
	var wave_sekarang = GameManager.current_wave
	var wave_maksimal = GameManager.MAX_WAVES
	
	# Perbarui teks informasi wave (Contoh hasil: "WAVE 1 / 3")
	wave_label.text = "WAVE %d / %d" % [wave_sekarang, wave_maksimal]
	
	# --- ANIMASI PENGISIAN BAR MENGGUNAKAN TWEEN ---
	# Membuat pergeseran isi bar menjadi halus (smooth transition) saat wave maju
	var tween = create_tween()
	tween.tween_property(wave_bar, "value", float(wave_sekarang), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# --- ANIMASI POP-UP KECIL PADA TEKS SAAT WAVE BERGANTI ---
	# Memberikan efek visual hentakan kecil agar player menyadari wave telah berganti
	var label_tween = create_tween()
	wave_label.pivot_offset = wave_label.size / 2.0 # Set pivot tepat di tengah teks
	label_tween.tween_property(wave_label, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	label_tween.tween_property(wave_label, "scale", Vector2.ONE, 0.1)
