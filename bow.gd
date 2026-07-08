extends Node3D

const ARROW_PROJECTILE_SCENE = preload("res://arrow.tscn")
@onready var muzzle: Marker3D = $Muzzle

@export var attack_cooldown: float = 0.5
var bisa_serang: bool = true

func _process(_delta: float) -> void:
	# REPLIKASI SINKRONISASI PEDANG: 
	# Biarkan 'walk.gd' yang muter tangan, busur cuma fokus ngecek action attack!
	if Input.is_action_just_pressed("attack") and bisa_serang:
		shoot_arrow()
		mulai_cooldown()

func shoot_arrow() -> void:
	if ARROW_PROJECTILE_SCENE == null:
		return
		
	var arrow_instance = ARROW_PROJECTILE_SCENE.instantiate()
	
	# KLONING PEDANG: Taruh di root yang sama biar posisi global 3D-nya sinkron!
	get_tree().root.add_child(arrow_instance)
	
	# Samakan posisi dan arah rotasi global panah dengan Muzzle senjata lu
	arrow_instance.global_transform = muzzle.global_transform
	
	# KASIH TAHU ARROW: Terbanglah ke depan sesuai arah sumbu X global si Muzzle!
	if "direction" in arrow_instance:
		arrow_instance.direction = muzzle.global_transform.basis.x.normalized()

func mulai_cooldown() -> void:
	bisa_serang = false
	await get_tree().create_timer(attack_cooldown).timeout
	bisa_serang = true
