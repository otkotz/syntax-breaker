# Dwa ludzkie runy telefonu — 2026-10-03

## Pochodzenie i zakres dowodu

Analiza dwóch runów wykonanych przez użytkownika po zatrzymaniu automatycznych testów.
Odczytano istniejące logi; nie uruchamiano kolejnych walk ani nie sterowano telefonem.
Snapshot: `.godot/phone-human-two-runs-20261003/files/telemetry`.
Osobny katalog wejściowy `.godot/phone-human-only-20261003` zawiera wyłącznie te dwa ID:

| Run / starter | Początek UTC | SHA-256 surowego JSON |
| --- | --- | --- |
| `b6300ae356fe3ee8f5d6fc79` / Lightning Bolt | 20:52:37 | `FC5E8AD8E56E517510DF02A52F8AE4EC1A56376775036100F49A710CC4A8C079` |
| `1ae5ccee848d916c7adc25c3` / Frost Nova | 20:59:35 | `B6898CBC30AFC4835FF3232AB6FE2689B597480258DA5BFB4F3D77EED0F9E0AF` |

Oba logi: Android, Godot 4.6.2, Ascension 0, Standard, MEDIUM (`quality=1`),
entity multiplier 0,75, cap 50, starting gold 30. Pole regionu jest puste;
nie traktować tych logów jako porównania trzech regionów. Telemetria nie zapisuje hasha APK.
Próby wykonano po instalacji APK ze strzałkami opisanej w protokole, lecz JSON sam nie
dowodzi wersji pakietu ani tego, czy użytkownik korzystał ze strzałek czy joysticka.

Wykluczono trzy znane ID automatyzacji ADB (`aefc20edecd62d0e906d10ca`,
`a240225f718b22b4519980ec`, `74bd602d39df3d4eb7156e10`), mimo `source=playtest`.
Starszy ludzki log `d525633d4866a3296130d6e6` pochodzi sprzed aktualizacji i nie wchodzi
do tego zbioru. Surowych danych nie zmieniano i nie dodano ich do repozytorium.

## Wyniki

| Pomiar | Lightning Bolt | Frost Nova |
| --- | --- | --- |
| Wynik / głębokość śmierci | death / 4 | death / 6 |
| Czas walki | 293,774 s | 294,103 s |
| Czas aplikacji | 411,765 s | 571,787 s |
| Zabójstwa / obrażenia | 238 / 6263,248 | 244 / 9598,250 |
| Gold earned / spent / remaining | 160,5 / 0 / 190,5 | 408 / 420 / 18 |
| Pierwsza decyzja w walce | 17,528 s | 17,526 s |
| Najdłuższy odstęp decyzji, z ogonem | 71,632 s | 35,733 s |
| Field Compilation / skip | 8 / 2 | 8 / 3 |
| Namysł nad Field Compilation | 70,491 s | 74,752 s |
| Oczekiwanie na spawn | 0,543 s | 0,576 s |
| Frame samples / klatki >33 ms | 17588 / 4 | 17602 / 6 |

Czas aplikacji obejmuje wybory, menu i pauzy mierzone przez silnik, nie jest dokładnym
czasem zegarowym. Namysł w tabeli obejmuje wyłącznie decyzje `kind=compilation`,
powiązane z `decision_chosen` przez ID; nie wszystkie nagrody ani zakupy.
Saldo uwzględnia początkowe 30 złota. Złoto niewydane w pierwszym runie nie dowodzi
przeoczenia zakupów: ta ścieżka nie doprowadziła do sklepu przed śmiercią.

## Przebieg i wnioski z logów

- Lightning Bolt: trzy pierwsze walki zakończone z 100 HP. Etap 4 to Elite + Deadly;
  pocisk obniżył HP do 95, następnie slam spowodował 95 → 0. Dwa auto-revive przywróciły
  po 30 HP, a kolejne dwa slamy ponownie wyzerowały zdrowie. Wszystkie trzy śmiertelne
  trafienia mają źródło `mini_boss:slam`; final build to Lightning Bolt z Returning i Spell Echo.
- Frost Nova: końcowy build zawiera Frost Nova, Lightning Bolt i Fireball. Boss na etapie 5
  został pokonany; jedyne zarejestrowane trafienie w tej walce to pocisk za 5 HP.
  Etap 6, Elite + Deadly, zaczął się z pełnym 70/70 HP po Glass Body i zakończył po
  15,420 s pojedynczym slamem 70 → 0. Nie była to stopniowa utrata HP.
- W drugim runie etap Enriched przyniósł 236 złota, około 58% całego zarobku.
  Między końcem bossa 5 a początkiem walki 6 było 148,101 s bez walki, na nagrody,
  wybory i sklep. Nie utożsamiać tej całej przerwy z Field Compilation ani awarią.
- Każdy run miał osiem przerw Field Compilation. Dane potwierdzają ich koszt czasowy,
  ale same pominięcia nie dowodzą bezwartościowości ofert. Zgłoszenie użytkownika,
  że wybory są zbyt częste i niezapowiedziane, pozostaje osobnym dowodem jakościowym.
- Odstęp 71,632 s w pierwszym runie przekracza próg 45 s. Jednocześnie same znaczniki
  checkpointów nie usuną nadmiaru przerw; nie zmieniać częstotliwości bez pogodzenia
  odczuć użytkownika z pierwotnymi kryteriami cadence.

Kod wskazuje na nakładanie mnożników slamu: baza kontaktu 20 × skalowanie głębokości
× etap Elite 1,5 × Deadly 1,4 × rola przeciwnika × slam 1,5. Na głębokości 4 daje to
98,28 dla zwykłego minibossa (rola 1,2) lub 106,47 dla elity (rola 1,3); log nie
rozróżnia tych instancji w źródle. Na głębokości 6 elita daje nominalnie 122,85 przed
dodatkowymi redukcjami. To obliczenie z aktualnego kodu, nie surowa wartość trafienia
z JSON: log zapisuje utracone HP i obcina overkill. Glass Body zwiększa ryzyko, ale
nominalny atak na etapie 6 przekracza również standardowe 100 HP.

## Gate'y i ograniczenia

Raport `.godot/phone-human-two-report.json`: 2 completed playtests, 0 invalid files,
0 duplicates, 0 dropped events, dwie śmierci `mini_boss:slam`.
Przy `--min-runs=50 --require-cadence` narzędzie zwróciło oczekiwany kod **2** oraz
`cadence.status=insufficient_data` (2/5). Nie dobierano korzystniejszych runów.
Przy mniej niż pięciu próbkach raport nie ocenia osobnych runów w `cadence.runs`;
najdłuższe odstępy w tabeli policzono osobno z pełnego JSON, wraz z pierwszą decyzją.
Suma pierwszej decyzji i odstępów zgadza się z czasem walki w obu logach.

Gate B nadal otwarty; Gate D wymaga 50–100 realnych runów i szerszych kohort.
Brak ciągłego nagrania uniemożliwia potwierdzenie czytelności ostrzeżeń i przyczyn
nieudanego uniku. Slam ma ostrzeżenie w kodzie, ale nie rejestruje `hazard_warning`;
brak takiego zdarzenia nie dowodzi braku wizualnego ostrzeżenia. Frame delta nie
zastępuje profilowania CPU/GPU ani oceny słabszego telefonu. Dwa zakończone JSON nie
potwierdzają 99% crash-free sesji ani poprawności resume. Nie zmieniono kodu ani balansu.

Odtworzenie raportu po przygotowaniu katalogu zawierającego wyłącznie oba ID:

```powershell
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' `
  --headless --path . --scene res://tests/telemetry_report.tscn `
  --log-file .godot/phone-human-two-report.log -- `
  --directory=res://.godot/phone-human-only-20261003 `
  --output=res://.godot/phone-human-two-report.json --min-runs=50 --require-cadence
```

Podczas lokalnej agregacji pojawił się znany komunikat środowiska o odczycie magazynu
certyfikatów Windows; raport został zapisany i odczytany. Nie interpretować tego
komunikatu jako błędu gry na telefonie ani kodu 2 jako przejścia gate'u.
