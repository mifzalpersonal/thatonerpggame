extends BaseEnemy

# 100% MANUT LEWAT SINI, TINGGAL GANTI ANGKA:

func ambil_max_hp() -> float:
	return 1.0 # Darah zombie lebih tebel

func ambil_speed() -> float:
	return 3.0  # Jalan zombie agak lambat

func ambil_radius() -> float:
	return 100.0 # Jarak pandang deteksi zombie
