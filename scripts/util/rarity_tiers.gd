class_name RarityTiers
extends RefCounted

# Rolled rarity tier for a skill copy. A skill's intrinsic .tres rarity is the FLOOR;
# luck can only roll it UP. Higher tier = more base damage.

const ORDER := ["common", "uncommon", "rare", "legendary"]

const DAMAGE_MULT := {
	"common": 1.0,
	"uncommon": 1.15,
	"rare": 1.35,
	"legendary": 1.6,
}

# Relative odds at luck 0 for tiers at/above the floor.
const BASE_WEIGHTS := {
	"common": 60.0,
	"uncommon": 25.0,
	"rare": 12.0,
	"legendary": 3.0,
}

# Each point of luck multiplies a tier's weight by pow(1 + luck * LUCK_FACTOR, tier_index),
# biasing the roll toward higher tiers.
const LUCK_FACTOR := 0.4

static func tier_index(tier: String) -> int:
	return maxi(ORDER.find(tier), 0)

static func damage_mult(tier: String) -> float:
	return DAMAGE_MULT.get(tier, 1.0)

static func roll_tier(floor_rarity: String, luck: float) -> String:
	var floor_idx := maxi(ORDER.find(floor_rarity), 0)
	var tiers: Array[String] = []
	var weights: Array[float] = []
	var total := 0.0
	var safe_luck := maxf(luck, 0.0)
	for i in range(floor_idx, ORDER.size()):
		var t: String = ORDER[i]
		var w: float = float(BASE_WEIGHTS[t]) * pow(1.0 + safe_luck * LUCK_FACTOR, float(i))
		tiers.append(t)
		weights.append(w)
		total += w

	if total <= 0.0:
		return floor_rarity

	var r := randf() * total
	var acc := 0.0
	for j in tiers.size():
		acc += weights[j]
		if r <= acc:
			return tiers[j]
	return tiers[tiers.size() - 1]
