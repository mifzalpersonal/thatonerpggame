extends Control

func _on_start_pressed():
	# Panggil fungsi autoload dengan path scene lobby kamu
	SceneChanger.change_scene_to("res://Scene/lobby.tscn")

func _on_credits_pressed():
	# Logika memunculkan panel credit kamu
	$CreditPanel.visible = !$CreditPanel.visible 

func _on_quit_pressed():
	get_tree().quit()
