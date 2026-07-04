extends Marker3D

var senjata_sekarang = ""
var node_senjata_di_tangan : Node = null

func ambil_senjata(nama_barang: String) -> void:
	if node_senjata_di_tangan != null:
		node_senjata_di_tangan.queue_free()
	
	senjata_sekarang = nama_barang
	print("Player berhasil ngambil ", nama_barang )
	
	var path_senjata = "res://" + nama_barang + ".tscn"
	
	if ResourceLoader.exists(path_senjata):
		var blueprint = load(path_senjata)
		var model_baru = blueprint.instantiate()
		add_child(model_baru)
		node_senjata_di_tangan = model_baru
	else:
		print("Eror: File senjata ", path_senjata, " gak ketemu!")

func eksekusi_menyerang() -> void:
	print("Menyerang pake: ", senjata_sekarang)
