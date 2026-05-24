class_name EngineTracker
extends RefCounted

# --- Crit Engine: Sharpened Edge ---
# On crit, gain stacking crit chance bonus that decays
static var _crit_streak_bonus: float = 0.0
static var _crit_streak_timer: float = 0.0
const CRIT_STREAK_GAIN := 0.03
const CRIT_STREAK_MAX := 0.15
const CRIT_STREAK_DURATION := 3.0

static func on_crit() -> void:
	if not _has_passive("sharpened_edge"):
		return
	_crit_streak_bonus = minf(_crit_streak_bonus + CRIT_STREAK_GAIN, CRIT_STREAK_MAX)
	_crit_streak_timer = CRIT_STREAK_DURATION

static func get_crit_streak_bonus() -> float:
	if _crit_streak_timer <= 0.0:
		return 0.0
	return _crit_streak_bonus

# --- Cast Speed Engine: Arcane Tempo ---
# Casting a DIFFERENT skill within the window grants stacking speed
static var _tempo_stacks: int = 0
static var _tempo_timer: float = 0.0
static var _tempo_last_skill: String = ""
const TEMPO_MAX_STACKS := 3
const TEMPO_DURATION := 4.0
const TEMPO_BONUS_PER_STACK := 0.08

static func on_cast(skill_id: String = "") -> void:
	if not _has_passive("arcane_tempo"):
		return
	if _tempo_timer > 0.0 and skill_id != _tempo_last_skill:
		_tempo_stacks = mini(_tempo_stacks + 1, TEMPO_MAX_STACKS)
	_tempo_last_skill = skill_id
	_tempo_timer = TEMPO_DURATION

static func get_tempo_cooldown_mult() -> float:
	if _tempo_stacks <= 0 or _tempo_timer <= 0.0:
		return 1.0
	return 1.0 - _tempo_stacks * TEMPO_BONUS_PER_STACK

# --- Poison Engine: Virulence ---
# Poison DoTs deal more damage per other DoT on the target
const VIRULENCE_BONUS_PER_DOT := 0.20
const VIRULENCE_MAX_STACKS := 3

static func get_virulence_mult(target: Node2D) -> float:
	if not _has_passive("virulence"):
		return 1.0
	var dots: Dictionary = target.get("_dots") if target else {}
	if dots.is_empty():
		return 1.0
	var dot_count := mini(dots.size() - 1, VIRULENCE_MAX_STACKS)
	if dot_count <= 0:
		return 1.0
	return 1.0 + dot_count * VIRULENCE_BONUS_PER_DOT

# --- AoE Engine: Detonation Expert ---
# AoE hits that strike 3+ enemies deal bonus damage
const DETONATION_THRESHOLD := 3
const DETONATION_BONUS := 0.20

static func get_detonation_mult(hit_count: int) -> float:
	if not _has_passive("detonation_expert"):
		return 1.0
	if hit_count >= DETONATION_THRESHOLD:
		return 1.0 + DETONATION_BONUS
	return 1.0

# --- Tick / Cleanup ---
static func tick(delta: float) -> void:
	if _crit_streak_timer > 0.0:
		_crit_streak_timer -= delta
		if _crit_streak_timer <= 0.0:
			_crit_streak_bonus = 0.0

	if _tempo_timer > 0.0:
		_tempo_timer -= delta
		if _tempo_timer <= 0.0:
			_tempo_stacks = 0

static func clear() -> void:
	_crit_streak_bonus = 0.0
	_crit_streak_timer = 0.0
	_tempo_stacks = 0
	_tempo_timer = 0.0
	_tempo_last_skill = ""

static func _has_passive(passive_id: String) -> bool:
	return PassiveBehaviors.has_passive(passive_id)
