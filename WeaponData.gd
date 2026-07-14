class_name WeaponData
extends Resource

@export var weapon_name: String = "Pedang Pemula"
@export var base_damage: float = 10.0
@export var forge_level: int = 0

# 🎯 SISTEM CRITICAL HIT
# Nilai default 0.10 berarti 10% peluang Crit. Bisa kamu ubah di tiap .tres senjata!
@export_range(0.0, 1.0) var crit_chance: float = 0.10 
@export var crit_multiplier: float = 3.0 # Pengali damage (3x lipat)

# Hitung damage dasar + bonus forge secara real-time (+15% per level tempa)
var total_damage: float:
	get:
		return base_damage + (base_damage * 0.15 * forge_level)

# ========================================================
# ⚔️ FUNGSI UNTUK MENGHITUNG DAMAGE SAAT MEMUKUL MUSUH
# ========================================================
# Fungsi ini mengembalikan Dictionary berisi total damage akhir 
# dan status apakah serangan tersebut Critical atau tidak (untuk VFX/Angka Pop-up)
func hitung_damage_output() -> Dictionary:
	var dadu = randf() # Menghasilkan angka acak antara 0.0 sampai 1.0
	var is_crit = dadu <= crit_chance
	
	var damage_akhir = total_damage
	if is_crit:
		damage_akhir = total_damage * crit_multiplier
		
	return {
		"damage": damage_akhir,
		"is_critical": is_crit
	}
