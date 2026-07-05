extends Control

# Ambil referensi ke AnimatedSprite2D (panah) yang ada di dalam masing-masing tombol
@onready var start_arrow = $VBoxContainer/Start/Control/ArrowSprite
@onready var credits_arrow = $VBoxContainer/Credits/Control/ArrowSprite
@onready var quit_arrow = $VBoxContainer/Quit/Control/ArrowSprite

func _ready():
	# Sembunyikan semua panah saat pertama kali masuk ke Main Menu
	start_arrow.visible = false
	credits_arrow.visible = false
	quit_arrow.visible = false

# =================================================================
# FUNGSI KLIK TOMBOL (SIGNAL: pressed)
# =================================================================

func _on_start_pressed():
	# Panggil fungsi autoload dengan path scene lobby kamu
	SceneChanger.change_scene_to("res://Scene/lobby.tscn")

func _on_credits_pressed():
	# Logika memunculkan panel credit kamu
	$CreditPanel.visible = !$CreditPanel.visible 

func _on_quit_pressed():
	get_tree().quit()


# =================================================================
# FUNGSI HOVER MOUSE YANG AKTIF (SIGNAL KEDETEKSI EDITOR)
# =================================================================

# --- TOMBOL START ---
func _on_start_mouse_entered():
	start_arrow.visible = true

func _on_start_mouse_exited():
	start_arrow.visible = false


# --- TOMBOL CREDITS ---
func _on_credits_mouse_entered():
	credits_arrow.visible = true

func _on_credits_mouse_exited():
	credits_arrow.visible = false


# --- TOMBOL QUIT ---
func _on_quit_mouse_entered():
	quit_arrow.visible = true

func _on_quit_mouse_exited():
	quit_arrow.visible = false
