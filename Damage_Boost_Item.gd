extends Area3D

@export var damage_multiplier: float = 2.0 # Menjadi 2x lipat
@export var duration: float = 7.0          # 7 detik

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta: float):
	rotate_y(2.0 * delta)

func _on_body_entered(body: Node3D):
	print("Item Damage Boost ditabrak oleh: ", body.name)
	
	# Pastikan yang menabrak adalah Player (Char3)
	if body is CharacterBody3D:
		if body.has_method("apply_damage_boost"):
			body.apply_damage_boost(damage_multiplier, duration)
			print("🔥 SUKSES: Fungsi apply_damage_boost di Player berhasil dipicu!")
			queue_free() # Hancurkan item
		else:
			print("🚨 ERROR: Ketemu Player, tapi Player gak punya fungsi 'apply_damage_boost'!")
	else:
		print("🚨 Peringatan: Yang nabrak item bkn Player, tapi: ", body.name)
