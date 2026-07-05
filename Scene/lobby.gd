extends Node3D

@onready var config_ui = $CanvasLayer/ConfigUI
@onready var ui_animation = $CanvasLayer/UIAnimation

func _ready():
	# Memaksa posisi UI berada di kondisi animasi tertutup (di luar layar kiri) saat awal masuk game
	if ui_animation.has_animation("close_ui"):
		ui_animation.play("close_ui")
		ui_animation.advance(1.0) 
	else:
		print("Peringatan: Animasi 'close_ui' tidak ditemukan di AnimationPlayer!")

# HUBUNGKAN KE SIGNAL: body_entered milik InteractionArea
func _on_interaction_area_body_entered(body: Node3D):
	print("Objek masuk area: ", body.name) # Untuk memastikan deteksi berjalan di konsol
	if body.name == "Char3":
		ui_animation.play("open_ui")

# HUBUNGKAN KE SIGNAL: body_exited milik InteractionArea
func _on_interaction_area_body_exited(body: Node3D):
	print("Objek keluar area: ", body.name)
	if body.name == "Char3":
		ui_animation.play("close_ui")

# HUBUNGKAN KE SIGNAL: pressed milik CloseButton kamu
func _on_close_button_pressed():
	ui_animation.play("close_ui")

# HUBUNGKAN KE SIGNAL: pressed milik PlayButton kamu
func _on_play_button_pressed():
	# Sembunyikan UI dengan animasi bergeser keluar dulu
	ui_animation.play("close_ui")
	await ui_animation.animation_finished
	
	# Panggil loading screen autoload kemarin untuk pindah ke map utama game
	SceneChanger.change_scene_to("res://Map-Asset/Scene/Main.tscn")
