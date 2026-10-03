# Audyt balansu — 2026-10-03

## Zakres i metoda

Test obejmuje katalog 7 skilli, 25 supportów, 55 pasywek i 8 mutacji. Dla każdego skilla sprawdzono wszystkie 6407 zgodnych zestawów 0–3 supportów. Na tych zestawach wykonano 1 427 745 wariantów z każdą pasującą pojedynczą pasywką (lub bez niej) i każdą dozwoloną pojedynczą mutacją (lub bez niej). Ten sam zakres przeszedł przez prawdziwe `SkillInstance` i `StatCalculator` w Godocie 4.6.2 bez błędnych lub niefinitych statystyk.

Oddzielnie skrypt statyczny sprawdził 2 079 285 par pasywek albo mutacji oraz 21 par skilli dla Arcane Tempo. Wszystkie 55 pasywek i 8 mutacji są reprezentowane; Arcane Tempo wymaga dwóch skilli, dlatego nie występuje w teście pojedynczego skilla. Dla świeżego profilu sprawdzono osobno 39 170 wariantów z trzech startowych skilli, dziesięciu startowych supportów i pasywek dostępnych na starcie.

Nie jest to enumeracja wszystkich podzbiorów pasywek i mutacji naraz — ich pełny iloczyn jest astronomiczny. Nie jest to też pomiar zwycięstw w rozegranych runach. Wskaźnik „bezpośredni DPS” zakłada 100% trafień, dla totemów dwa stale aktywne totemy; nie modeluje przeżywalności, obszaru trafień, większości efektów wyzwalanych, DoT, ruchu wrogów ani RNG. Służy do wyłapywania anomalii, nie do określania szansy na wygraną.

## Wyniki wymagające działania

1. **Niedostępna zawartość jest głównym ograniczeniem różnorodności.** Na świeżym profilu 10 supportów i 10 pasywek nie jest dostępnych początkowo ani przez żaden zasób odblokowania. Reward picker i sklep filtrują zawartość przez `MetaProgression.is_unlocked`, więc te przedmioty nie trafią do normalnej puli nagród. Supporty: `arc_burst`, `corpse_bloom`, `crit_cascade`, `echo_trigger`, `glass_cannon`, `overcharge`, `plague_carrier`, `ricochet_amplifier`, `shotgun`, `toxic_burst`. Pasywki: `arcane_tempo`, `blast_radius`, `brutal_precision`, `conduction`, `detonation_expert`, `lightning_rod`, `overclocked`, `patient_hunter`, `sharpened_edge`, `virulence`. Priorytet: dodać warunki odblokowania lub świadomie włączyć je do puli startowej.

2. **Niektóre połączenia supportów wyłączają się nawzajem bez ostrzeżenia.** W 61 zestawach `Totem` wygrywa z `Mine`; w 61 zestawach `Totem` wyłącza `Spell Echo`; w 94 zestawach `Mine` wyłącza `Spell Echo`. Wynika to z kolejności gałęzi w `SkillCaster`, nie z obliczeń DPS. Ponadto `Mine` nie wysyła zdarzeń `notify_hit`/`notify_kill` do zachowań supportów. Dla 16 supportów dołączenie do miny nie daje wykrywalnego dodatniego efektu bezpośredniego; część z nich może nadal wpływać na inne mechaniki. 32 006 testowanych wariantów łączy minę z mutacją `Piercing` lub `Scatter`, która w tym trybie nic nie daje. Priorytet: zablokować takie oferty albo nadać kombinacjom jawnie zdefiniowany efekt.

3. **Mutacja może ominąć limit liczby pocisków.** W 12 175 wariantach natywny `SkillInstance` uzyskał `projectile_count > 8`. `StatCalculator` ogranicza statystyki do 8, a `SkillInstance` nakłada mutacje dopiero później. Najpierw trzeba ustalić, czy limit 8 ma obejmować mutacje; jeśli tak, należy klamrować wynik końcowy.

4. **Istnieją skrajne konfiguracje szybkości i liczby obiektów.** W 361 wariantach z dwiema pasywkami cooldown spada do minimum 0,05 s (np. `Faster Casting` + jego mastery + `Overclocked`). Model lotu pocisków oszacował ponad 60 jednoczesnych pocisków w 407 wariantach, a skrajny wynik to około 157,5. Przy starcie dostępne są już 4 warianty powyżej 50. To sygnał do profilowania wydajności; nie jest to pomiar rzeczywistej liczby obiektów w scenie.

5. **Wskaźnik bezpośredniego DPS ma bardzo szeroki rozrzut, ale nie rozstrzyga o sile w grze.** Najwyższy szacunek wyniósł 746,67 dla `Lightning Bolt` + `Faster Casting` + `Shotgun` + `Totem`, pasywki `No-Crit Juggernaut` i mutacji `Scatter`; bazowy `Lightning Bolt` ma 16,4 w tym samym uproszczonym modelu. Górne wyniki zależą od założenia, że wszystkie pociski trafiają. Obszarowe skille i poison są przez ten wskaźnik niedoszacowane. Kolejnym krokiem powinny być powtarzalne symulacje walki i pomiar przeżywalności, nie prosty nerf według tej liczby.

## Naprawione podczas audytu

- Usunięto BOM UTF-8 z 24 zasobów pasywek `*_mastery.tres`, których Godot wcześniej nie wczytywał.
- Poprawiono klasyfikację `Fire Mastery` w `BuildOptions`: jest pasywką żywiołową, nie mastery supportu. Test natywny weryfikuje ofertę dla Fireballa, brak oferty dla Frost Nova i wynik obrażeń Fireball + Chain + Fire Mastery.
- Dodano test natywny wykrywający brakujące zasoby, niepoprawne statystyki i pokrycie wszystkich pasywek/mutacji oraz statyczny test kombinacji i osiągalności odblokowań.

## Powtórzenie

```powershell
python tests\balance_audit.py
python tests\balance_audit.py --starter-only
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --log-file .godot\balance_native.log --scene res://tests/balance_native.tscn
```

Godot uruchomiono wyłącznie headless; nie uruchamiano Brotato ani interfejsu gry.
