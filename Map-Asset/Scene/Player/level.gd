extends Node

var user_level : int = 1
var user_exp : int = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("exp") :
		user_exp += 50
		print("exp nambah 50 yaa")
	if user_exp == 100 :
		user_level += 1
		user_exp = 0
		print("selamat antum naek level")
