extends Area3D

const weapon_drop = preload("res://WeaponDrop.tscn")

const daftar_senjata = [
	"hugs",
	"hugs_fire",
	"katana",
	"sword_slim",
	"sword_slim_nature",
	"bow"
]

var udah_kebuka : bool = false
var player_deket : CharacterBody3D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_kalomasuk)
	body_exited.connect(_kalokeluar)
	$PetunjukE.visible = false 
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if udah_kebuka == false and player_deket != null:
		if Input.is_action_just_pressed("interaction") :
			buka_peti()
			print("you pressed E")
		pass

func _kalomasuk(body : Node3D) -> void:
	if udah_kebuka == false and body is CharacterBody3D:
		player_deket = body
		$PetunjukE.visible = true
		print("lu deket chest")

func _kalokeluar(body : Node3D) -> void:
	if body is CharacterBody3D:
		player_deket = null
		$PetunjukE.visible = false
		print("lu ngga deket chest")

func buka_peti() -> void:
	udah_kebuka = true
	$PetunjukE.visible = false
	
	var indeks_acak = randi() % daftar_senjata.size()
	print(indeks_acak)
	var senjata_terpilih = daftar_senjata[indeks_acak]
	print(senjata_terpilih)
	
	var hasil_gacha = weapon_drop.instantiate()
	hasil_gacha.global_position = global_position + Vector3(0, 1.0, 0)
	hasil_gacha.nama_senjata = senjata_terpilih
	
	
	get_tree().current_scene.add_child(hasil_gacha)
	print("you just opened a chest")
	
	
	
	
