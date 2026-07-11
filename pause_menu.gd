extends Control

func _ready():
	hide()

func _unhandled_input(event):
	if event.is_action_pressed("Menu"):
		toggle_pause()

func toggle_pause():
	var new_pause_state = !get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state
	
	if new_pause_state:
		show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
	else:
		hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
	visible = get_tree().paused

# 1. Tombol Balik ke Game
func _on_resume_button_pressed():
	toggle_pause()

# 2. Tombol Kembali ke Lobby
# 2. Tombol Kembali ke Lobby
func _on_lobby_button_pressed():
	# Unpause game sebelum pindah agar game di scene baru tidak macet/beku
	get_tree().paused = false
	print("Tombol Lobby berhasil diklik!") # <-- Tambahkan ini unt
	
	GameManager.reset_game()
	
	# Pindah ke scene lobby menggunakan Autoload/Singleton SceneChanger kamu
	SceneChanger.change_scene_to("res://Scene/lobby.tscn")

# 3. Tombol Kembali ke Main Menu
func _on_main_menu_button_pressed():
	get_tree().paused = false 
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.queue_free()
		
	SceneChanger.change_scene_to("res://main_menu_model.tscn")
