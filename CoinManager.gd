extends Node

# Sinyal yang akan berbunyi tiap kali koin berubah
signal coin_changed(new_amount: int)

# Variabel penyimpan total koin player
var total_coins: int = 0

func add_coins(amount: int):
	total_coins += amount
	# Tembakkan sinyal ke UI agar teks koin di layar otomatis ter-update
	coin_changed.emit(total_coins)
	print("Koin bertambah! Total sekarang: ", total_coins)

func reduce_coins(amount: int) -> bool:
	if total_coins >= amount:
		total_coins -= amount
		coin_changed.emit(total_coins)
		return true # Transaksi sukses (koin cukup)
	else:
		print("Koin gak cukup!")
		return false # Transaksi gagal (miskin koin)
