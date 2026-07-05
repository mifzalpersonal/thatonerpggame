extends Marker3D

var slot_senjata = ["", ""]
var slot_aktif = 0
var node_senjata_di_tangan : Node = null

var senjata_sekarang : String:
	get:
		return slot_senjata[slot_aktif]

func ambil_senjata(nama_barang: String) -> void:
	slot_senjata[slot_aktif] = nama_barang
	print("Slot ", slot_aktif + 1, " diisi: ", nama_barang)
	pasang_visual_senjata(nama_barang)

func ganti_slot(nomor_slot: int) -> void:
	var indeks_baru = nomor_slot - 1
	if indeks_baru == slot_aktif:
		return
		
	slot_aktif = indeks_baru
	print("Swapped ke Slot: ", nomor_slot)
	pasang_visual_senjata(slot_senjata[slot_aktif])

func pasang_visual_senjata(nama_barang: String) -> void:
	if node_senjata_di_tangan != null:
		node_senjata_di_tangan.queue_free()
		node_senjata_di_tangan = null
		
	if nama_barang == "":
		return
		
	var path_senjata = "res://" + nama_barang + ".tscn"
	
	if ResourceLoader.exists(path_senjata):
		var blueprint = load(path_senjata)
		var model_baru = blueprint.instantiate()
		add_child(model_baru)
		node_senjata_di_tangan = model_baru
	else:
		print("Eror: File senjata ", path_senjata, " gak ketemu!")

func eksekusi_menyerang() -> void:
	if slot_senjata[slot_aktif] != "":
		print("Menyerang pake: ", slot_senjata[slot_aktif])
