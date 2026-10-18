# Expedition loot-hunt tuning

## Current targets

- Elite and treasure rooms must always yield an artifact or Ember Shards; an empty result is a defect.
- Across seeded synthetic cohorts, at least 75% must discover an artifact by victory five and 95% by victory eight.
- Covenant of Embers should complete within eight victories in at least 80% of cohorts.
- Bloodwritten Sigil keeps its fifth-victory pity guarantee. Blood Omen raises the natural chance from 15% to 25%, but adds one boss depth.
- No Ember Forge commitment may exceed 60% of purchases across the three synthetic policies.
- Duplicate decisions must retain meaningful samples for Echo, Temper and Shatter rather than collapsing into a single dominant action.

## Seeded baseline — 2026-10-18

`tests/expedition_balance_simulation_native.tscn` runs 400 deterministic cohorts of eight victories.

| Metric | Result | Gate |
| --- | ---: | ---: |
| Elite/treasure empty-room rate | 0.0% | 0% |
| Mean new artifacts by victory 5 | 5.915 | at least 2 |
| Mean new artifacts by victory 8 | 5.998 | at least 3 |
| Covenant complete by victory 8 | 99.75% | at least 80% |
| Mean first Sigil victory | 3.795 | at most 5 |
| Forge maximum share | 45.04% | at most 60% |

The first state-driven simulation exposed overuse of Discovery Ward and then Treasure Choice. Forge prices were retuned to Treasure Choice 20, Discovery Ward 30 and Covenant Mark 25 shards; drop chances and shard awards remain unchanged. Real playtest telemetry remains the authority for later balance changes; this simulation catches deterministic regressions, not player preference.

## Telemetry contract

Expedition events are allow-listed, size-bounded and idempotent by stable event ID. The event stream covers room source, rolled result, reward decision, effective loadout delta, Forge commitment and post-run settlement. Payloads exclude device/platform identifiers and arbitrary metadata. Resume restores recorded event keys, preventing a checkpoint replay from double-counting the same decision or reward.

Presentation animation is observational only. Buttons and state transitions do not wait for a reveal tween, every reveal is skippable, shards/duplicates use a short treatment, and reduced motion lands directly on the final usable frame.
