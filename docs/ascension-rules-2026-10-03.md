# Jakościowe reguły Ascension — 2026-10-03

Oprócz skalowania HP/damage/speed i ograniczania regeneracji run ma trzy progi zmieniające
skład spotkań. Są kumulatywne i dotyczą wyłącznie węzłów Combat/Elite od głębokości 2.
Pierwsza arena, bossy, treasure i shop są wyłączone.

| Próg | Modyfikator mapy/HUD | Dodatkowy spawn |
| --- | --- | --- |
| A5 | Elite Patrol | Jeden elite z istniejącym affixem przy pulsie 3 |
| A10 | Denial Reinforcement | Caster przy pulsie 2, jeśli pozwala limit dwóch |
| A15 | Shield Reinforcement | Shield support przy pulsie 4, jeśli pozwala limit jednego |

Reguła jest zapisana w węźle mapy, a nie dodawana niewidocznie podczas ładowania areny.
Wchodzi do save wraz z modyfikatorami StageTree i do telemetrii stage_start. Stary aktywny
save bez tych znaczników nie otrzymuje ich retroaktywnie; kolejny nowy run wygeneruje je
według wybranego, regionalnie odblokowanego poziomu.

Dodatkowe cele nie pomniejszają podstawowego budżetu fali, liczą się do żywych przeciwników
i muszą zostać pokonane przed końcem etapu. Każdy wyznaczony puls jest obsługiwany raz;
reentrant request nie duplikuje wzmocnienia, nowy setup czyści licznik. Przy osiągniętym
limicie caster/shield spawn jest pomijany, nie zamieniany w nadmiarowy trash. Odległość,
skalowanie, telegraphy, aura i affix korzystają z dotychczasowych implementacji.

To jakościowe utrudnienia, nie potwierdzony balans: wcześniejszy caster i elite w pierwszym
akcie mogą istotnie zmieniać win-rate. HUD/mapa pokazują ich nazwy, ale czytelność przy
wielu jednoczesnych modyfikatorach wymaga testu na telefonie. Nie zamyka to gate'u encounterów.

Symulator ekonomii używa wspólnego `StageData.get_scripted_roles()` i nalicza złoto
dodatkowych celów, z zachowaniem ograniczeń modelu natychmiastowego czyszczenia każdego
pulsu. Raporty dostają `model_revision=ascension_opening_roles_v1`. Przebiegi 48/480 po tej
zmianie przeszły. Osiemnasta iteracja odtworzyła również pełne 10 000 bez błędów bilansu
i ostrzeżeń sprzątania: `.godot/economy_ascension_10000.json`, seed 20261003, 149,513 s.
Wcześniejszy raport 10 000 sprzed tych reguł pozostaje historyczny. Aktualne wyniki i
ograniczenia opisuje `docs/economy-audit-2026-10-03.md`.

`tests/ascension_rules_native.tscn` sprawdza granice 4/5, 9/10, 14/15, A20, wyjątki etapów,
mapę, serializację, kolejność pulsów, faktyczne spawny przez scheduler, idempotencję i capy.
Pozostałe testy natywne oraz cleanup symulatora 48/480 i smoke przechodzą.
