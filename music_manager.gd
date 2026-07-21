extends AudioStreamPlayer

var BGM = {
	"res://main_menu_model.tscn": preload("res://music/main-menu.wav"),
	"res://Scene/lobby.tscn": preload("res://music/main-menu.wav"),
	#"res://Map-Asset/Scene/Main.tscn": preload("res://music/in-game.wav")
	"res://Map-Asset/Scene/Main.tscn": preload("res://music/figth-boss.wav")
}

func _ready() -> void:
	Events.mute_toggled.connect(_on_mute_requested)
	
	get_tree().root.child_entered_tree.connect(_on_scene_changed)

func _on_scene_changed(node: Node) -> void:
	if node.scene_file_path and node.scene_file_path != "":
		playBGM(node.scene_file_path)

func playBGM(scene_path: String):
	if BGM.has(scene_path):
		var target_music = BGM[scene_path]
		
		if stream != target_music:
			stream = target_music
			play()

func playBossMusic(file_path: String) -> void:
	var target_music = load(file_path)
	
	if stream != target_music:
		stream = target_music
		play()

func _on_mute_requested(should_mute: bool) -> void:
	AudioServer.set_bus_mute(0, should_mute)
