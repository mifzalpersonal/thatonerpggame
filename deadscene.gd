extends Control

func _ready() -> void:
	# Memaksa mouse muncul di layar agar bisa ngeklik tombol
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# MEMAKSA SCENE INI TETAP JALAN MESKIPUN GAME DI-PAUSE
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func _on_lobby_pressed() -> void:
	# Unpause game sebelum pindah agar game di scene baru tidak macet/beku
	get_tree().paused = false
	print("Tombol Lobby berhasil diklik!") # <-- Tambahkan ini unt
	
	GameManager.reset_game()
	
	# Pindah ke scene lobby menggunakan Autoload/Singleton SceneChanger kamu
	SceneChanger.change_scene_to("res://Scene/lobby.tscn")

func _on_main_menu_pressed() -> void:
	# PENTING: Wajib di-unpause juga di sini agar Main Menu tidak ikut membeku!
	get_tree().paused = false
	
	GameManager.reset_game()
	
	SceneChanger.change_scene_to("res://main_menu_model.tscn")
