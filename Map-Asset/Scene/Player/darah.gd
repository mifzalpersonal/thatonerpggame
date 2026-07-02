extends Node
class_name darah

@export var hp = 100.0

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if hp <= 0:
		print("elu mokad")
