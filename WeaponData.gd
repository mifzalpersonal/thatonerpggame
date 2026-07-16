class_name WeaponData
extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export_category("Base Weapon Info")
@export var weapon_name: String = "Katana"
@export var base_damage: int = 50
@export var forge_level: int = 0

@export_category("Rarity Setup")
@export var current_rarity: Rarity = Rarity.COMMON

# ==============================================================================
# 💎 DIATUR DI INSPECTOR: BONUS DAMAGE PER RARITY
# ==============================================================================
@export_group("Rarity Damage Bonuses")
@export var common_bonus_damage: int = 0
@export var uncommon_bonus_damage: int = 15
@export var rare_bonus_damage: int = 35
@export var epic_bonus_damage: int = 65
@export var legendary_bonus_damage: int = 110

# ==============================================================================
# 🎯 DIATUR DI INSPECTOR: BONUS CRIT CHANCE PER RARITY (Tulis 0.03 untuk 3%)
# ==============================================================================
@export_group("Rarity Crit Bonuses")
@export_range(0.0, 1.0) var common_bonus_crit: float = 0.0
@export_range(0.0, 1.0) var uncommon_bonus_crit: float = 0.03   # 3%
@export_range(0.0, 1.0) var rare_bonus_crit: float = 0.07       # 7%
@export_range(0.0, 1.0) var epic_bonus_crit: float = 0.12       # 12%
@export_range(0.0, 1.0) var legendary_bonus_crit: float = 0.20  # 20%

@export_category("Base Critical Hit Setup")
@export_range(0.0, 1.0) var base_crit_chance: float = 0.05 # 5% Peluang crit dasar bawaan senjata
@export var crit_multiplier: float = 1.5 # 1.5x damage saat crit default

@export_category("Rarity Gacha Chance (Total must be 1.0 / 100%)")
@export_range(0.0, 1.0) var chance_common: float = 0.50     # 50%
@export_range(0.0, 1.0) var chance_uncommon: float = 0.30   # 30%
@export_range(0.0, 1.0) var chance_rare: float = 0.15       # 15%
@export_range(0.0, 1.0) var chance_epic: float = 0.04       # 4%
@export_range(0.0, 1.0) var chance_legendary: float = 0.01  # 1%

# ==============================================================================
# 🔄 GETTER DINAMIS UNTUK TOTAL DAMAGE & TOTAL CRIT CHANCE
# ==============================================================================

# Variabel kalkulasi akhir damage yang dibaca oleh GameManager
var total_damage: int:
	get:
		# Kunci level tempaan secara internal agar kalkulasi matematika damage mentok di level 24
		var level_aman = clampi(forge_level, 0, 24)
		return base_damage + get_rarity_bonus() + (level_aman * 5)

# Variabel kalkulasi akhir crit chance (Base + Bonus Kasta)
var crit_chance: float:
	get:
		return base_crit_chance + get_rarity_crit_bonus()

# ==============================================================================
# 🛠️ FUNGSI INTERNAL PENGHITUNG BONUS KASTA
# ==============================================================================

# Ambil bonus damage berdasarkan kasta rarity aktif
func get_rarity_bonus() -> int:
	match current_rarity:
		Rarity.COMMON: return common_bonus_damage
		Rarity.UNCOMMON: return uncommon_bonus_damage
		Rarity.RARE: return rare_bonus_damage
		Rarity.EPIC: return epic_bonus_damage
		Rarity.LEGENDARY: return legendary_bonus_damage
	return 0

# Ambil bonus crit berdasarkan kasta rarity aktif
func get_rarity_crit_bonus() -> float:
	match current_rarity:
		Rarity.COMMON: return common_bonus_crit
		Rarity.UNCOMMON: return uncommon_bonus_crit
		Rarity.RARE: return rare_bonus_crit
		Rarity.EPIC: return epic_bonus_crit
		Rarity.LEGENDARY: return legendary_bonus_crit
	return 0.0

# Mendapatkan string nama Rarity (untuk visual UI)
func get_rarity_name() -> String:
	match current_rarity:
		Rarity.COMMON: return "Common"
		Rarity.UNCOMMON: return "Uncommon"
		Rarity.RARE: return "Rare"
		Rarity.EPIC: return "Epic"
		Rarity.LEGENDARY: return "Legendary"
	return "Unknown"

# ==============================================================================
# 🎲 SISTEM KANG KOCOK DAMAGE & CRIT SAAT PELURU DILEPAS
# ==============================================================================
func hitung_damage_output() -> Dictionary:
	var akhir_damage: float = float(total_damage)
	var apakah_crit: bool = false
	
	# Kocok menggunakan gabungan total crit_chance dinamis (Base + Rarity)
	if randf() <= crit_chance:
		apakah_crit = true
		akhir_damage = akhir_damage * crit_multiplier
		
	return {
		"damage": int(akhir_damage),
		"is_critical": apakah_crit
	}
