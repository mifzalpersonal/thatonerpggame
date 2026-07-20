extends PanelContainer

@onready var wave_label: Label = $Margin/Layout/WaveLabel
@onready var wave_bar: ProgressBar = $Margin/Layout/WaveBar

func _ready() -> void:
	visible = false 
	
	# Ambil data kondisi awal wave saat ini
	update_wave_ui()
	
	# Hubungkan sinyal perubahan level jika sewaktu-waktu level/wave berganti secara global
	if GameManager.has_signal("level_changed"):
		GameManager.level_changed.connect(update_wave_ui)

## Fungsi utama untuk memperbarui tampilan teks dan bar progress secara real-time
func update_wave_ui() -> void:
	var wave_sekarang = GameManager.current_wave
	var wave_maksimal = GameManager.MAX_WAVES
	
	# Perbarui teks informasi wave (Contoh hasil: "WAVE 1 / 3")
	wave_label.text = "WAVE %d / %d" % [wave_sekarang, wave_maksimal]
	
	# 🔥 SOLUSI UTAMA VISUAL: Kita paksa isi kapasitas bar berbasis rasio/persentase.
	# Dengan cara ini, bar akan tahu seberapa besar porsi "1 wave" di dalam total kapasitas baru.
	wave_bar.min_value = 0.0
	wave_bar.max_value = float(wave_maksimal)
	
	# Jika balik ke wave 1 (baru naik level), langsung kosongin bar secara instan biar kapasitas barunya kelihatan reset
	if wave_sekarang == 1:
		wave_bar.value = 0.0
		
	# --- ANIMASI PENGISIAN BAR MENGGUNAKAN TWEEN ---
	# Menghitung pergerakan isi bar secara mulus berdasarkan proporsi kapasitas max_value yang baru
	var tween = create_tween()
	tween.tween_property(wave_bar, "value", float(wave_sekarang), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# --- ANIMASI POP-UP KECIL PADA TEKS SAAT WAVE BERGANTI ---
	var label_tween = create_tween()
	wave_label.pivot_offset = wave_label.size / 2.0 # Set pivot tepat di tengah teks
	label_tween.tween_property(wave_label, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	label_tween.tween_property(wave_label, "scale", Vector2.ONE, 0.1)
