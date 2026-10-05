# Poprawki po audycie walki — 2026-10-05

Wdrożono zakres z [audytu](combat-readability-audit-2026-10-05.md).

## Zmiany

- Pociski wrogów: glow jest pierwszą warstwą, następnie ciemny kontur, czerwona
  obwódka i nieprzezroczysty biały rdzeń. Kolejność lokalna, bez zmiany generatora
  innych grafik. Render nad skillami i hazardami (`z_index=20`), filtr nearest.
  Hitbox pozostaje o promieniu 7.
- Hazardy bossów, caster i affixy elite mają wspólny wygląd faz: ostrzeżenie
  z przerywanym żółtym obrysem, postępem po obwodzie i pozostałym czasem;
  aktywna strefa ma mocniejsze wypełnienie, ciągły obrys, znaki zagrożenia oraz
  etykietę ACTIVE. Pierwszą aktywną klatkę podkreśla błysk 0,25 s.
  Czasy warningów, geometria bezpiecznych obszarów i odstępy ticków pozostają zgodne
  z mechaniką. Wedge/rotating_gap wskazuje wycięcie strzałką SAFE.
- Slam: ostrzeżenie 1,25 s z odliczaniem całego obszaru zamiast pulsujących małych
  łuków. Przy uderzeniu błyska cały promień 120; rozszerzający się ozdobny pierścień
  nie jest już jedynym sygnałem natychmiastowego trafienia.
- Duzi przeciwnicy (`MiniBoss`, elite i bossowie regionalni) używają łagodniejszego
  skalowania damage: `sqrt(damage_mult)`. Zachowano wzrost przez etap, region,
  Deadly, rolę i Ascension. Kontakt bazuje na bazowym contact damage, a slam ma
  osobny budżet `28 × sqrt(damage_mult)` zamiast contact ×1,5.
  Zmiana obejmuje również hazardy i volley wywodzące damage z kontaktu oraz affixy
  elit; ich siła obniża się razem z kontaktem. Nie ogranicza obrażeń do procentu
  aktualnego HP gracza i nie zapewnia nieśmiertelności na wysokim Ascension.
- Melee/ranged: sprite ×1,5; tank ×1,25; swarm ×0,85 zamiast ×0,5, czyli 70%
  większy niż wcześniej. Zmieniono wyłącznie sylwetki; collidery i skalę całego
  CharacterBody2D zachowano. Paski zdrowia i statusy uwzględniają górę powiększonej
  tekstury. Bossowie zachowują własne skale; większe proceduralne sylwetki
  chargera/castera/shielda/splittera nie są globalnie rozciągane.
- Telemetria: player_damage dodaje raw_amount, mitigated_amount, max_hp oraz
  attacker_id/attacker_role dla kontaktu, slamu, pocisków i hazardów. Pole amount
  nadal oznacza rzeczywistą utratę HP, więc stare raporty zachowują zgodność.
  Slam zapisuje warning z promieniem i instancją/rolą; hazardy rejestrują też
  jednorazowe hazard_active. ID instancji służy tylko korelacji ataków w danym
  uruchomieniu gry. Starszych JSON nie uzupełniano sztucznymi danymi.

## Wynik balansu w sprawdzonym najtrudniejszym wariancie A0

Test używa prawdziwego spawnera i Player: etap Elite + Deadly, Burning Grounds,
rola elite, pełne 100 HP, bez redukcji. Wyniki wykonania:

| Głębokość | Slam przed zmianą, nominalnie | Slam po zmianie | Kontakt po zmianie |
| --- | --- | --- | --- |
| 4 | 117,117 | 55,323 | 39,517 |
| 6 | 135,135 | 59,427 | 42,448 |
| 10 | 171,171 | 66,882 | 47,773 |

Poprzednie slamy 95→0 i 70→0 w archiwum są dowodem starego balansu, nie wynikiem
tej wersji. Nowe wartości wymagają ludzkiej oceny feelingu. Inne obrażenia w grze
oraz wyższe Ascension nie mają uniwersalnej ochrony przed śmiercią od jednego ataku.
Stałe pociski ranged za 5 HP pozostawiono jako jawnie osobny budżet; nie zwiększono
ich damage podczas naprawy widoczności.

## Weryfikacja

`tests/combat_readability_native.tscn` najpierw wykazał regresje przeciwko staremu
kodowi: nadpisany rdzeń, małe sylwetki, pełne zabicie slamem, brak danych overkill
i max HP. Osobna faza RED wykazała brak warningów slamu oraz sygnału aktywacji.
Po zmianach końcowy test kończy się PASS i kodem 0. Pokrywa też zachowanie colliderów,
reset puli, unik poza promieniem, bezpieczny sektor po aktywacji i tick delay.

Przeszło **20 natywnych scen** z katalogu tests (wszystkie poza narzędziem
`telemetry_report.tscn`, które nie jest testem): ascension_rules, balance, boss,
cadence, catalog, challenges, combat_readability, contracts, cosmetics, damage,
economy_cleanup, economy_simulation, encounter, node_routes, run_integrity,
shop_affinity, splitter, telemetry, telemetry_report_native i test_controls.
Symulacja ekonomii: 10 000 runów, 0 failures. Logi:
`.godot/readability-suite-*.log`; końcowy nowy test:
`.godot/combat-readability-final.log`.
Starsze skrypty `extends GutTest` nie były uruchamiane: repozytorium nie zawiera
instalacji GUT. Powyższy wynik dotyczy kompletu dostępnych natywnych scen.

Sprawdzono renderowane obrazy w dokładnym offscreen viewport 1080×1920:
`.godot/readability-warning.png`, `.godot/readability-activation.png`,
`.godot/readability-active.png`. Są to rzeczywiste komponenty Godota na statycznej
planszy kontrolnej przy skali odpowiadającej zoomowi 2×. Nie zastępują nagrania
zatłoczonej walki na telefonie ani pomiaru mobilnego GPU. Renderer kontrolny:
OpenGL Compatibility, Radeon RX 6600.

Zbudowano podpisane debug APK:
`builds/SyntaxBreaker-combat-readability-20261005.apk`.
SHA-256: `4DAB563FD1D9712BC6934D25859C96BC48919C1613B18A843823D2D27DF68482`.
Eksport Android: kod 0, podpisanie i weryfikacja zakończone. Nowy helper i test
są w pakiecie. Po rozpakowaniu APK uruchomiono nową scenę regresyjną z jego
skompilowanych zasobów: PASS, identyczny budżet obrażeń. To test zasobów APK na
desktopowym Godocie, nie test działania systemu Android.

W logach pozostaje komunikat środowiska o odczycie certyfikatów Windows.
Eksport dodatkowo zgłosił odmowę zapisu cache/ustawień edytora poza workspace,
brak ikony projektu i fallback build-tools 36.1.0; mimo tego podpisany APK
został zapisany, zweryfikowany i sprawdzony po rozpakowaniu. Nie deklarować
czystego logu eksportu ani gotowości do publicznego wydania.
APK zachowuje istniejące ustawienia debug preset, w tym phone_test_controls.

Nie instalowano APK ani nie sterowano telefonem. Bezpośredni następny krok to
playtest nowego builda i ocena czytelności w ruchu; większy goal grafik/UI/defensywy
z [zakresu](active-goal-scope-2026-10-05.md) nadal pozostaje aktywny.
