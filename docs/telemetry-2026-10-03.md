# Lokalna telemetria runów — 2026-10-03

Aktualizacja 2026-10-05: `player_damage` zachowuje `amount` jako faktyczną stratę
HP, a dodaje `raw_amount`, `mitigated_amount`, `max_hp` i kontekst instancji/roli
napastnika dla ataków wrogów. Umożliwia to odróżnienie overkill i dobicia od
full-HP one-shota. Slam zapisuje `hazard_warning` z promieniem i rolą; strefy
bossów/castera/affixów zapisują `hazard_active` raz przy rozpoczęciu aktywności.
Pola są dodatkiem zgodnym ze starym raportem, a nie danymi dopisanymi do starych
logów. ID instancji jest lokalne dla uruchomienia gry. Szczegóły w
[raporcie poprawek](combat-readability-fixes-2026-10-05.md).

Osłona: `player_damage.amount` nadal oznacza wyłącznie utratę HP. Nowe pola
`shield_absorbed`, `shield_before`, `shield_after` opisują pochłonięcie ciosu.
`mitigated_amount` pozostaje siłą ciosu po redukcji obrażeń, przed osłoną.
Suma `shield_absorbed` w `run_stats` jest osobna od `damage_taken` (utrata HP).

Rejestrator `RunTelemetry` zapisuje jeden JSON na run w `user://telemetry` (katalog danych
użytkownika Godota). Nie wysyła danych przez sieć, nie zapisuje identyfikatorów kont ani
modelu urządzenia. Losowy `run_id` identyfikuje przebieg, a nie osobę. Log zawiera datę UTC,
platformę, wersję silnika, region, Ascension, preset jakości, starter i końcowy build.

## Pomiar

- Osobne zegary czasu aplikacji i walki; czas myślenia obejmuje pauzę wyboru, czas walki nie.
  Przerwa między zamknięciem aplikacji a wznowieniem nie jest doliczana.
- Pierwsza decyzja po rozpoczęciu walki, odstępy między kolejnymi okazjami do decyzji i ogon
  do końca runu. Starter i mapa przed rozpoczęciem walki nie zerują pierwszego pomiaru.
- Oczekiwanie na spawn: aktywna fala z pozostałym czasem, bez żywych przeciwników i bez
  oczekujących fragmentów. Nie obejmuje pauzy ani czytania nagród.
- Etapy, liczby spawnów według roli, zabójstwa, HP/złoto na granicach etapów, oferty i wybory,
  zakupy, zwroty oraz rerolle. Shop purchase jest zdarzeniem transakcji, nie dowodem
  zachowania anulowanego przedmiotu; final build i shop refund pozwalają to rozróżnić.
- Rzeczywiste przyjęte trafienia wraz ze źródłem, HP i pozycją. I-frame/god mode nie nadpisuje
  źródła; auto-revive zapisuje odrodzenie, nie śmierć. Podsumowanie pokazuje źródło śmierci.
  Ostrzeżenia chargera, castera, affixów elite i hazardów regionalnych bossów zapisują źródło,
  pozycję i czas ostrzeżenia. Log nie zastępuje nagrania czytelności telegraphu.
- Średni i maksymalny czas klatki walki oraz udział klatek powyżej 33 ms. Dane headless nie
  dowodzą wydajności telefonu. Zebrane delty nie zastępują profilera CPU/GPU.

Checkpoint logu jest zapisywany atomowo przez plik `.tmp` i rename. Snapshot telemetrii
wchodzi do aktywnego save; resume zachowuje ID i wcześniejsze pomiary. Stare zapisy bez
telemetrii rozpoczynają nową, jawnie niepełną rejestrację. Limit 5000 zdarzeń ogranicza
pamięć; `dropped_events` ujawnia obcięcie. Zagregowane liczniki nadal są aktualizowane.
Logi nie mają jeszcze automatycznej retencji; można skopiować lub usunąć katalog telemetry
po zakończeniu runu. Włączony rejestrator zbiera lokalne logi także w zwykłym buildzie.

## Raport

Przykład PowerShell; ścieżkę do Godota należy dostosować do instalacji:

```powershell
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' `
  --headless --path . --scene res://tests/telemetry_report.tscn `
  --log-file .godot/telemetry_report.log -- --min-runs=50
```

Domyślnie czyta `user://telemetry`; `--directory=<ścieżka>` pozwala analizować skopiowane logi
telefonu. Raport trafia do `.godot/telemetry_report.json`; można wskazać `--output=<ścieżka>`.
Nie modyfikuje logów wejściowych. Kod `0` oznacza zapis raportu i spełnienie podanego minimum,
`2` — zbyt mało zakończonych playtestów, `1` — błąd zapisu raportu. Bez `--min-runs` brak
próbek nie jest błędem wykonania, ale nie stanowi dowodu gotowości.

Opcja `--require-cadence` dodatkowo wymaga pozytywnego sprawdzenia liczbowego pięciu
ostatnich zakończonych realnych runów. Raport `cadence` pokazuje ID, datę, pierwszą decyzję,
najdłuższy odstęp (wraz z początkowym oczekiwaniem i końcowym ogonem), oczekiwanie na spawn
oraz powody odrzucenia. Wymaga pierwszej decyzji poniżej 30 s i każdego odstępu nie większego
niż 45 s. Nie wybiera pięciu najlepszych runów z całej historii. Remis dat na granicy wyboru,
uszkodzone pliki lub sprzeczne kopie tego samego run ID uniemożliwiają potwierdzenie.
Niepełne resume i obcięte zdarzenia również nie potwierdzają pełnego pomiaru. Suma odstępów
musi pokrywać zarejestrowany czas walki; brak końcowego odcinka nie ukryje długiej przerwy.

`passed_numeric_checks` dotyczy wyłącznie tych progów, nie całego Milestone B: odmienna
funkcja ekonomiczna każdego węzła i jakość decyzji nadal wymagają oceny gry. Raport odrzuca
nieprawidłowe typy pól, ujemne/nieskończone czasy i sprzeczne liczniki; uszkodzona próbka
nie zwiększa liczby ukończonych playtestów. Identyczne kopie logu są liczone raz.

Raport zawiera liczby zwycięstw i śmierci, win-rate per region/Ascension/jakość/starter,
źródła śmierci, p10/medianę/p90/max czasów oraz pick-rate względem rzeczywistej dostępności
opcji w pickerach. Sklepy nie są traktowane jako pojedynczy wybór jednej oferty. Dodatnie
odstępy są raportowane osobno, aby seria ekranów przy zerowym czasie walki nie zaniżała
mediany. Nieukończone logi nie dowodzą crasha; raport nie deklaruje crash-free rate.

Headless i jawne fixture'y mają `source=synthetic`. Są domyślnie wykluczone. Opcja
`--include-synthetic` służy tylko diagnostyce; nawet wtedy próbki syntetyczne nie spełniają
progu `--min-runs`. Nie należy mieszać ich win-rate z wynikami graczy.

## Weryfikacja i otwarte gate'y

`tests/telemetry_native.tscn` przeszedł 50 syntetycznych sekwencji zapisu/wznowienia, pauzę
decyzji, podwójne kliknięcie, zapis atomowy, źródła trafień, auto-revive, limit zdarzeń,
stary/niezgodny save i agregację raportu. Pozostałe fixture'y pokrywają śmierć, porzucenie
oraz nieukończony log. Test raportu potwierdza wykluczenie wszystkich 53 fixture'ów oraz kod
`2` dla wymogu 50 playtestów. Sześć wcześniejszych zestawów natywnych i smoke 300 klatek
również przeszły.

`tests/telemetry_report_native.tscn` sprawdza dodatkowo wybór ostatnich pięciu, niezależność
od kolejności plików, progi 30/45 s, brak ogona, częściowy resume, wykluczenie synthetic,
remisy dat, uszkodzone pola i duplikaty. Źródło `playtest` jest mockowane wyłącznie w pamięci
testu; fixture'y zapisane na dysku pozostają synthetic i nie stanowią danych graczy.

To nie jest zbiór 50 realnych runów. Pozostają: pomiar pięciu kolejnych pełnych runów dla
cadence, 50–100 playtestów, nagrania śmierci i czytelności na 1080×1920, pomiar słabszego
telefonu, ocena archetypów i strojenie balansu. Raport opisuje pomiary, nie zamyka tych gate'ów.
