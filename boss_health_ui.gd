extends Control

@onready var boss_bar: ProgressBar = $BossBar
@onready var boss_name_label: Label = $BossNameLabel

var boss_ref: CharacterBody3D = null
var active: bool = false

func _ready() -> void:
	# Awal game disembunyikan dulu sampai si boss beneran lahir
	visible = false
	
	# Daftarkan UI ini ke group agar bisa ditembak sinyalnya oleh boss.gd
	add_to_group("BossUI")

func _process(delta: float) -> void:
	# Proteksi: Kalau tidak aktif atau bossnya mati/di-queue_free, langsung sembunyikan UI
	if not active or boss_ref == null or not is_instance_valid(boss_ref):
		if visible:
			visible = false
		return

	# Ambil nyawa boss secara real-time
	if "current_hp" in boss_ref:
		var target_hp = boss_ref.current_hp
		
		# Animasi darah berkurang smooth (Mulus ga kaku) pakai Tween
		var tween = create_tween()
		tween.tween_property(boss_bar, "value", float(target_hp), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# Fungsi pemicu utama yang bakal dipanggil otomatis dari fungsi _ready() si Boss
func aktifkan_health_bar(target_boss: CharacterBody3D) -> void:
	boss_ref = target_boss
	active = true
	
	if "max_hp" in boss_ref and "current_hp" in boss_ref:
		boss_bar.max_value = float(boss_ref.max_hp)
		boss_bar.value = float(boss_ref.current_hp)
		
	visible = true
	print("📺 BOSS UI: Health Bar resmi diaktifkan di layar!")
