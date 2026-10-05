# Audyt walki i czytelności — 2026-10-05

Zakres: logi gry, widoczność pocisków wrogów, ground effecty bossów (w tym
„Pacman”), one-shoty oraz wielkość przeciwników. Audyt aktualnego `main`, HEAD
`234f4ac`. Nie zmieniono mechanik, balansu ani zainstalowanej gry.

Po tym audycie użytkownik zlecił wdrożenie. Zmiany i ich weryfikację opisuje
[raport poprawek](combat-readability-fixes-2026-10-05.md); poniższe ustalenia
techniczne i obliczenia dotyczą wersji przed poprawkami.

## Źródła i ograniczenia

Pierwszy odczyt ADB 2026-10-05 zwrócił pustą listę. Po ponownym sprawdzeniu na
prośbę użytkownika telefon RMX5131 był dostępny. Pobrano wszystkie 9 plików przez
`exec-out run-as com.example.syntaxbreaker tar -cf - files/telemetry` do osobnego
snapshotu `.godot/phone-combat-audit-20261005`. Archiwum `telemetry.tar` ma SHA-256
`0855F8F20E2345DAF4F5515A3448CF3596E4CD4553AE17231F46D3AD37047FA1`.
Sprawdzono listę archiwum przed rozpakowaniem i odczytano wszystkie 9 JSON.
Nie sterowano telefonem ani nie uruchamiano automatycznych walk.

Ponownie odczytano surowe JSON, nie tylko wcześniejszy raport:

| Run | Snapshot | SHA-256 |
| --- | --- | --- |
| `b6300ae356fe3ee8f5d6fc79` | `.godot/phone-human-only-20261003` | `FC5E8AD8E56E517510DF02A52F8AE4EC1A56376775036100F49A710CC4A8C079` |
| `1ae5ccee848d916c7adc25c3` | `.godot/phone-human-only-20261003` | `B6898CBC30AFC4835FF3232AB6FE2689B597480258DA5BFB4F3D77EED0F9E0AF` |
| `81fcc956133f8854c672043d` | `.godot/phone-latest-20261003-2356/files/telemetry` | `CC2E8ED10C3042D83B513EF1EC652E7AA10E4401F30AA0DC619A49332D046FDA` |

Pierwsze dwa runy mają wcześniej udokumentowane ludzkie pochodzenie
(`phone-human-runs-2026-10-03.md`). Trzeci jest późniejszym archiwalnym logiem
Android `source=playtest`, ale to pole samo nie gwarantuje gry człowieka: wcześniejsze
próby automatyzacji również miały tę etykietę. Analizowany osobno, bez dopisywania
do zweryfikowanej kohorty ludzkiej. Wszystkie trzy: Ascension 0, brak dropped events,
status death, przyczyna `mini_boss:slam`. Region w metadata jest pusty. JSON nie
zawiera hasha APK; porównanie z aktualnym kodem nie dowodzi identyczności buildów.
Ostrzeżenia `burning_boss:wedge` i `burning_boss:wall` w dwóch logach pozwalają
rozpoznać konkretne ataki mimo pustego regionu.

## 1. Pociski wrogów: potwierdzony błąd generowania tekstury (P0)

`scripts/enemies/enemy_projectile.gd::_build_orb_texture()` deklaruje jasny rdzeń,
czerwone obrzeże i glow o alfa 0,3. `scripts/util/pixel_sprite.gd::build_texture()`
najpierw zapisuje prostokąty, następnie koła przez `img.set_pixel()`.
Nie wykonuje kompozycji alfa. Koło glow o promieniu 8 obejmuje cały rdzeń i nadpisuje
go półprzezroczystym kolorem. Kod sugeruje jasną kulkę, ale gotowa tekstura jej nie ma.

Pomiar w Godot 4.6.2, `.godot/combat-audit-probe-20261005.log`:

- Tekstura: 20×20 px z paddingiem; wizualna kula ma około 16 jednostek średnicy.
- Piksel środka: RGBA `(1.0, 0.2, 0.098, 0.298)`.
- Liczba pikseli o alfa >0,9: **0**.
- Collider: promień 7, czyli średnica 14 jednostek, mimo bardzo słabego krycia.
- Ten sam generator obsługuje ranged i volley minibossa.

To bezpośredni dowód techniczny przyczyny słabej widoczności. Brak nagrania nie
pozwala policzyć widoczności w zatłoczonej walce. Nie trzeba jednak zgadywać, czy
jasny rdzeń jest renderowany: został nadpisany.

Rekomendacja: narysować glow pod rdzeniem (lokalna kolejność dla tej tekstury albo
osobna warstwa); sprawdzić wszystkich użytkowników `PixelSprite` przed globalną
zmianą kolejności. Nadać pociskom wrogów stały, jasny rdzeń, ciemny kontur oraz
czytelną warstwę nad efektami gracza. Test regresyjny ma sprawdzać gotową alfę
rdzenia, a nie tylko deklarowane kolory. Dopiero potem stroić rozmiar.

## 2. „Pacman” i ground effecty: działanie poprawne, sygnał fazy słaby (P1)

Najbardziej prawdopodobne dopasowanie nazwy „Pacman” to `wedge` Burning Grounds;
ostateczne potwierdzenie wymaga obrazu wskazanego efektu. Kod rysuje koło z wyciętym
bezpiecznym sektorem. **Wypełnione 270° jest niebezpieczne; wycięte 90° jest bezpieczne.**
`rotating_gap` Storm Spire w fazie II ma tę samą geometrię i obracający się wycinek.

`scripts/enemies/boss_hazard.gd` podczas ostrzeżenia wraca przed obsługą damage.
Na klatce wyzerowania warning również wraca; pierwsza następna aktywna klatka
może już zadać obrażenia (`tick_remaining` startuje od 0). Nie ma dodatkowych
0,5 s łaski po zakończeniu ostrzeżenia; 0,5 s to odstęp kolejnych ticków.

| Efekt | Ostrzeżenie | Aktywność | Trafienia |
| --- | --- | --- | --- |
| Burning wall | 1,2 s | 3 s | od pierwszej aktywnej klatki, potem co 0,5 s |
| Burning wedge | 1,3 s | 2 s | od pierwszej aktywnej klatki, potem co 0,5 s |
| Storm beam | 1 / 1,65 / 2,3 s | 0,4 s każdy | jeden tick na linię |
| Toxic pool | 1,2 s | 5 s | od pierwszej aktywnej klatki, potem co 0,5 s |
| Reguły fazy II: border / rotating_gap / pressure | 2 s | do końca encounteru | co 0,5 s przy pozostaniu w zagrożeniu |

W `_draw()` obrys ma ten sam kolor i grubość w obu fazach. Główna zmiana to
alfa wypełnienia **0,12 → 0,32**. Nie ma wskaźnika odliczania ani osobnego impulsu
aktywacji. Taka różnica jest słabym sygnałem, zwłaszcza wśród nakładających się efektów.

Próba aktualnego `wedge` w Godot: damage 0 przed aktywacją, 0 na klatce kończącej
warning, 25,2 na pierwszej aktywnej klatce; punkt w wyciętym sektorze pozostaje
bezpieczny. Logi zawierają po trzy warningi `burning_boss:wedge` w runach Frost Nova
i Poison Dart, ale nie zawierają trafień tym efektem. Nie przypisywać mu tych śmierci.

Rekomendacja: wspólny język faz hazardów: ostrzeżenie z odliczaniem i odmiennym
wzorem obrysu, wyraźny impuls aktywacji, trwały wzór zagrożenia podczas damage.
Różnicę oprzeć również na ruchu/kształcie, nie samym kolorze i alfa. Bezpieczny
wycinek oznaczyć kierunkowo. Wizualna granica ma odpowiadać `threatens()`.

## 3. One-shoty: potwierdzony slam minibossów/elit (P0)

| Run / etap | Źródło | Zmiana HP | Interpretacja |
| --- | --- | --- | --- |
| Lightning Bolt / 4, Elite + Deadly | mini_boss:slam | 95 → 0 | pojedyncze śmiertelne trafienie po wcześniejszym pocisku 5 HP |
| ten sam run po dwóch revive | mini_boss:slam | 30 → 0, 30 → 0 | kolejne śmiertelne slamy, nie kolejne full-HP one-shoty |
| Frost Nova / 6, Elite + Deadly | mini_boss:slam | 70 → 0 | pojedynczy full-HP one-shot po Glass Body |
| Poison Dart / 6, Combat + Tough | mini_boss:slam | 68,8 → 10,3 | rzeczywiste 58,5 damage; przeżyte trafienie |
| Poison Dart / 7, Elite + Tough + Swift | mini_boss:slam | 10,3 → 0 | dobicie, nie dowód one-shota z pełnego HP |

Kod skaluje bazowe contact damage 20 przez głębokość, typ etapu, Deadly,
region, Ascension i rolę, a slam dodatkowo przez 1,5.

Przy neutralnym regionie i Ascension 0:

- Głębokość 4, Elite + Deadly, rola miniboss: `20 × 1,3 × 1,5 × 1,4 × 1,2 × 1,5 = 98,28`.
- Ten sam etap, rola elite: zamiast 1,2 używa 1,3, wynik **106,47**.
- Głębokość 6, Elite + Deadly, rola elite: **122,85**.
- Głębokość 6, Combat + Tough, rola elite: **58,5** — zgodne z nieśmiertelnym trafieniem w późniejszym logu.

`Glass Body` obniża max HP do 70%, ale 122,85 przekracza także standardowe 100 HP.
Źródło `mini_boss:slam` nie odróżnia roli elite od minibossa, więc pierwszego
śmiertelnego trafienia nie można jednoznacznie przypisać do konkretnej instancji.
Log `amount` obcina overkill do bieżącego HP, a nie zapisuje nominalnego damage.

Regionalni bossowie nadpisują zachowanie ataku i używają hazardów; analizowane
śmierci nie pochodzą z ich ground effectów. Nazwa „boss” w odczuciu gracza obejmuje
również duże elity, ale technicznie są to inne ścieżki ataku i skalowania.

Slam ostrzega przez 1 s, zapamiętuje pozycję gracza, teleportuje przeciwnika do
tej pozycji i natychmiast sprawdza promień 120. Animacja shockwave pojawia się
**po** sprawdzeniu obrażeń; rozszerzający się pierścień nie oznacza rozszerzającego
się hitboxa. Warning to cienkie pulsujące łuki, a nie jednoznaczne odliczanie.
Slam nie zapisuje `hazard_warning`, więc log nie pozwala ocenić czasu jego ostrzeżenia.
I-frame 0,5 s blokuje kolejne trafienia, ale nie ogranicza pierwszego dużego damage.

Rekomendacja: rozdzielić budżet damage umiejętności od mnożników kontaktu i określić
docelową stratę HP dla A0, szczególnie Elite + Deadly. Uniknąć niezamierzonego
przekraczania pełnego bazowego HP przez skumulowane mnożniki. Glass Body może
pozostać świadomym ryzykiem, ale nie wyjaśnia one-shotów standardowego buildu.
Slam potrzebuje czytelnego odliczania całego obszaru; impuls damage ma zbiegać się
z momentem uderzenia. Telemetria powinna zapisywać warning, ID instancji/rolę,
raw damage, damage po redukcjach, effective loss i max HP.

## 4. Wielkość wrogów: pomiar potwierdza małe sylwetki (P1)

Pomiar wygenerowanych tekstur po cropie, ze skalą sprite'ów i zoomem Camera2D 2×:

| Wróg | Tekstura po cropie | Skala sprite'a | Na 1080×1920 | Na oknie 540×960 |
| --- | --- | --- | --- | --- |
| Gremlin / melee | 17×20 | 1 | 34×40 px | 17×20 px |
| Oracle / ranged | 17×32 | 1 | 34×64 px | 17×32 px |
| Brute / tank | 27×34 | 1 | 54×68 px | 27×34 px |
| Mote / swarm | 15×26 | 0,5 | 15×26 px | 7,5×13 px |

To rozmiary prostokątów tekstur, a nie wypełnionej powierzchni całej sylwetki;
cienkie fragmenty są jeszcze mniejsze. Rozmiar bufora autora (np. 32×36) nie jest
rozmiarem gotowego sprite'a: `IndexBuffer._bake()` wycina przezroczyste marginesy.
Brak późniejszego powiększenia w EnemyBase. Swarm dodatkowo zmniejsza sprite o połowę.
Rozmiar fizyczny konkretnego telefonu zależy od wyświetlacza i skalowania.

Rekomendacja: stroić docelową wysokość i szerokość sylwetek po cropie, zachowując
hierarchię swarm < melee/ranged < tank < elite/boss. Kandydat do playtestu: melee
około 1,5× obecnego rozmiaru, swarm około 1,5–2× obecnego rozmiaru. To propozycja,
nie zweryfikowane wartości finalne. Powiększenie całego CharacterBody2D zmienia
również collider; decyzję o skali sprite'a i kolizji należy podjąć świadomie,
uwzględniając położenie stóp, paski HP, separację i gęstość areny.

## Uzupełnienie po pobraniu aktualnych logów

Telefon przechowuje 9 runów: 8 zakończonych śmiercią i 1 in_progress. To zbiór
mieszany; zawiera trzy wcześniej rozpoznane próby ADB oraz starszy build. Nie
wyliczać z całości ludzkiego win-rate ani nie zaliczać jej do gate'u playtestów.
Najnowsze pliki zapisano 2026-10-04 o 00:19 i 00:28 według listy urządzenia;
nie znaleziono runu rozpoczętego 5 października.

Dwa dodatkowe logi, których nie było w trzech wcześniejszych próbkach audytu:

| ID / początek Europe/Warsaw | Wynik | Dowód |
| --- | --- | --- |
| `6d6bfbdcb5aa4baebd328751` / 2026-10-04 00:13:32 | śmierć, głębokość 4 Combat + Deadly + Cursed | slam 91,52 → 13,442 (78,078 damage), po 5,7 s kolejny slam 13,442 → 0 |
| `f263507e61b592c567ff3a06` / 2026-10-04 00:19:08 | śmierć, głębokość 6 Elite + Deadly + Swift | na głębokości 4 slam 95 → 16,922 (78,078 damage); po pociskach śmiertelny kontakt fragmentu i revive; na bossie 5 kontakt 30 → 0 i drugi revive; finalnie kontakt minibossa 35 → 0 |

Oba: Static Field, Burning Grounds, Ascension 0, MEDIUM, source=playtest,
dropped_events=0. Pochodzenia ludzkiego nie potwierdza samo pole source, więc
analizowane jako osobny zbiór. Hash pierwszego JSON:
`FFF10B7750D77F0379456502066FAF801649102B5F5EBDFD2A77CAC0B4CC7056`;
drugiego: `A4F832146466E46578214542AD2B9E51051E6629860C1FDFD80C006ACAF1831C`.

Wartość 78,078 odpowiada aktualnej ścieżce elite na etapie Combat 4 w Burning
Grounds: `20 × 1,3 × 1,4 × 1,1 × 1,3 × 1,5`. Regionalne +10% damage i wymuszone
Deadly wzmacniają ataki już na zwykłych etapach; przy etapie Elite dochodzi kolejny
mnożnik 1,5. W Burning Grounds odpowiednik slamu elite na głębokości 6 z Deadly
wynosi nominalnie **135,135**, zanim zastosowane zostaną ewentualne redukcje gracza.
Finalny kontakt 35 → 0 w drugim logu nie dowodzi full-HP one-shota: gracz zaczął
ten etap z 35 HP i przez całą tę walkę ma tylko jedno przyjęte trafienie.

Drugi log zawiera sześć ostrzeżeń wall i sześć wedge, ale żadnego przyjętego
trafienia ground effectem bossa. Kontakt bossa jest osobnym zagrożeniem, także
w czasie przemieszczania się w celu uniknięcia hazardu. Wymaga uwzględnienia
przy projektowaniu bezpiecznej drogi; same bezpieczne pola hazardu nie blokują kontaktu.

Agregacja wyłącznie dwóch nowych ID: `later-two-report.json` w katalogu snapshotu,
2 zakończone runy, 0 invalid. Nie miesza dawnych prób ADB z nowymi próbkami.

## Dodatkowa niespójność

`BasicRanged._fire_projectile()` używa stałego `projectile_damage=5`, podczas gdy
`EnemyBase.apply_scaling()` skaluje `contact_damage`. Pociski zwykłego ranged nie
dziedziczą tych samych mnożników damage co kontakt, slamy i boss hazardy.
Logi potwierdzają powtarzalne trafienia 5 HP na późniejszych etapach. Nie podnosić
ich automatycznie: mogłoby to pogorszyć balans przed naprawą widoczności. Należy
jednak jawnie ustalić, czy odmienna reguła skalowania jest zamierzona.

## Weryfikacja i kolejność działań

Wykonano:

1. Ponowny odczyt trzech surowych logów, hashy, etapów, trafień i warningów.
2. Agregację późniejszego snapshotu przez `tests/telemetry_report.tscn`: exit 0,
   1 zakończony playtest, 0 invalid; `.godot/latest-audit-20261005.json`.
3. `tests/boss_native.tscn`: exit 0, PASS regionalnych bossów, warningów, bezpiecznych
   obszarów i faz II; `.godot/boss-audit-20261005.log`. Test nie dowodzi jakości grafiki.
4. Lokalną sondę Godot `.godot/combat_audit_probe_20261005.tscn`: pomiar gotowego
   pocisku i sprite'ów oraz klatek aktywacji wedge; końcowe wykonanie bez błędów skryptu.
   Godot zgłasza błąd odczytu magazynu certyfikatów Windows; nie dotyczy badanych
   mechanik offline. Pierwsze próby sondy wymagały poprawki uruchomienia jako sceny,
   aby autoloady były dostępne; dowodem jest końcowe wykonanie.

Priorytety wdrożenia: **P0 jasny rdzeń pocisków i budżet damage slamu; P1 język faz
hazardów i docelowe rozmiary sylwetek**. Następnie test na telefonie: zatłoczona
walka z efektami gracza, nagranie warning→activation każdego hazardu, slam na
A0 z pełnym HP przy Elite + Deadly oraz czytelność wszystkich ról.

Pobranie aktualnego snapshotu i audyt czterech zgłoszonych problemów wykonano.
Audyt nie jest dowodem naprawienia gry: implementacja rekomendacji oraz wizualna
walidacja urządzenia to kolejne prace. Czytelność potwierdzono na poziomie błędu
tekstury, geometrii i rozmiarów, a nie oceną nagrania zatłoczonej walki.
