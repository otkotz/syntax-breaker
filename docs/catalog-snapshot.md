# Katalog zasobów — kontrolowany snapshot

Blok pochodzi z wczytanych zasobów Godota, puli mutacji i rejestru zachowań.
Test `tests/catalog_native.tscn` porównuje go z projektem, sprawdza unikalność ID
oraz zgodność plików z rejestrem eksportu na Androida. Liczba zasobów nie oznacza,
że wszystkie są dostępne na świeżym profilu.

<!-- catalog:start -->
| Category | Count |
| --- | ---: |
| skills | 7 |
| supports | 25 |
| passives | 55 |
| unlocks | 40 |
| regions | 3 |
| consumables | 8 |
| mutations | 12 |
| registered behaviors | 20 |

Mutation IDs: `close_quarters`, `concentrated`, `crit_master`, `explosive`, `giant`, `hair_trigger`, `heavy_payload`, `piercing`, `rapid_fire`, `scatter`, `sniper`, `vampiric`.

RegionResource exported fields: `ambient_particle_color`, `bg_color`, `border_color`, `damage_mult`, `description`, `enemy_tint`, `favored_mutations`, `favored_tags`, `grid_color`, `hp_mult`, `id`, `name`, `rarity`, `stage_modifiers`.
<!-- catalog:end -->

## Odtworzenie i aktualizacja

```powershell
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --scene res://tests/catalog_native.tscn --log-file .godot/catalog_native.log
```

Test zapisuje blok w `.godot/catalog_snapshot.md`. Po świadomej zmianie katalogu należy
przejrzeć różnicę i zaktualizować blok w tym dokumencie. Argument `-- --emit` pomija tylko
porównanie dokumentacji; nadal waliduje zasoby i rejestr eksportu. Nie nadpisuje dokumentacji
ani profilu gracza.
