extends RigidBody3D

@export var nama_senjata : String = "Sabit Biru"
# jujur gua yang ngoding aja bingung kenapa ini dinamain sabit biru tapi karna work yaudahlah yah biarin aja

func _ready() -> void:
	$AmbilArea.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D :
		if body.has_node("Tangan"):
			var tangan = body.get_node("Tangan")
			if tangan.has_method("ambil_senjata"):
				tangan.ambil_senjata(nama_senjata)
			queue_free()
		
