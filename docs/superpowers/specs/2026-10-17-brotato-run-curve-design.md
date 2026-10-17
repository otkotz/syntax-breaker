# Brotato-style Run Curve

## Intent

Keep combat moving, make optional terminal fights fair throughout a run, prevent the shop from completing a perfect build too cheaply, and preserve exciting rewards after a skill reaches evolution tier III.

## Design

- Normal encounters spawn on cadence while they have budget and remain below a soft concurrent-enemy cap. A lone enemy never blocks the next pulse.
- Compilation terminals scale from both stage depth and a deterministic build-power score. Early terminals use smaller waves and wider zones; strong late builds face more enemies, elites, and tougher terminal-only scaling.
- Shop rerolls retain escalating cost across shop visits. Costs rise on a triangular curve, so several rerolls remain possible but forcing exact items consumes meaningful gold.
- A max-tier skill becomes eligible for a rare permanent `Kernel Overclock` terminal reward. Each stack grants multiplicative damage and cooldown power, has a hard cap, is saved with the run, and replaces the low-value endless support-slot fallback.

## Bounds

- No new currency or inventory screen.
- No enemy despawning merely because it is far away.
- Normal chest rewards keep their current three-choice structure.
- Existing saves load with zero overclock stacks.

