extends CharacterBody3D

@export var speed = 3.0
@onready var musuh = $AnimatedSprite3D

var player_node : CharacterBody3D
# var musuhBuatNyerang : musuhbody

func _ready() -> void:
	player_node = get_node_or_null("/root/Main/CharacterBody3D")

func _process(delta: float) -> void:
	if player_node != null:
		var ngejar = player_node.global_position - global_position
		ngejar = ngejar.normalized()
		velocity = ngejar * speed
		move_and_slide()
		
		for i in get_slide_collision_count():
			var collided = get_slide_collision(i).get_collider()
				#get slide collision count tuh ngitung berapa yang nabrak
				#get slide collision tuh ngitung yang mana
			if collided == player_node :
					var health_component = player_node.get_node_or_null("darahEntity")
					if health_component != null :
						health_component.hp -= 0.5
						print("Hp lu ngurang segini ", health_component.hp, " bang")
				
