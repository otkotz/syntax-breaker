# Playtest telefonu — wymagane dowody

## Uzupełnienia celu: czytelność i Field Compilation

Status: wymagania dodane na prośbę użytkownika; implementacja jeszcze nie wykonana.
Nie wznowiono automatycznego testowania telefonu.

- Charger: podmienić trójkątny placeholder na czytelnego pikselowego przeciwnika.
  Kandydat grafiki `assets/sprites/charger-v1.png` przedstawia rogatego tarana w
  ciemnofioletowym pancerzu z pomarańczowymi akcentami, na przezroczystym tle.
  Podpięcie wymaga akceptacji wyglądu; nie zmieniać HP, obrażeń, ruchu ani kolizji.
- Field Compilation: obecnie są dwa progi czasowe, 35% i 70%, a nie licznik zabójstw.
  Górny HUD pokazuje pozostały czas fali, procent postępu i liczbę przeciwników;
  nie pokazuje czasu do wyboru ani oznaczeń checkpointów.
- Dodać znaczniki momentów Field Compilation na istniejącym górnym pasku oraz
  krótki licznik pozostałych wyborów z odliczaniem do następnego. Rozróżnić moment
  oczekujący i już wykorzystany również inaczej niż samym kolorem. Nie sugerować,
  że override jest trwałą pasywką — działa tylko w bieżącej walce.
- Harmonogram i licznik muszą wynikać ze stanu areny. Odliczanie zatrzymuje się w
  pauzie, nie restartuje po wyborze/skipie i nie zapowiada kolejnego wyboru po ostatnim.
  Uwzględnić wcześniejsze zakończenie etapu i otwarcie checkpointu tylko raz.
- Osobno ocenić nadmierną częstotliwość przerywania walki, zgłoszoną przez użytkownika.
  Dwa ludzkie runy zawierały po osiem wyborów i około 70–75 s namysłu nad nimi.
  Nie uznawać znaczników za rozwiązanie częstotliwości ani samodzielnie zmieniać
  progów/duration bez uzgodnienia; pierwotne gate'y cadence pozostają obowiązujące.
- Weryfikacja: natywna regresja zgodności HUD z checkpointami, wyboru/skipu/pauzy,
  braku kolejnego odliczania po ostatnim oraz ręczna ocena czytelności na telefonie.
  Test headless nie dowodzi, że przerwy są przyjemne lub że oznaczenia są czytelne.

## Build i stan przygotowania

Debug APK: `builds/SyntaxBreaker-playtest.apk`, pakiet `com.example.syntaxbreaker`.
Eksport Godot 4.6.2 zakończony; podpis APK zweryfikowany. SHA-256:
`A08F75F3509D235C9943FB7B0AEBF4A9B2AC01F4037AA2F193FE0E827DC3FD22`.
Hash dotyczy tej iteracji; ponowny eksport może go zmienić.

Test bossów/cadence przeszedł na zasobach wcześniejszych APK. Po naprawie zamykania pickera
ponowiono eksport i test przejść węzłów na zasobach bieżącego APK, bez źródłowych scen projektu.
To kontrola pakowania, nie uruchomienie Androida ani pomiar telefonu. Eksport nadal zgłasza
brak własnej ikony, fallback build-tools oraz ograniczenia zapisu cache/settings edytora
w sandboxie. Nie zgłasza już błędów parsowania scen bossów.

Telefon został sparowany kodem podanym przez użytkownika; ADB potwierdziło połączenie.
Read-only kontrola wykazała Android 16/API 36, model RMX5131 i ekran 1080×2362.
Po osobnej zgodzie użytkownika skopiowano telemetrię do
`.godot/phone-capture-20261003/telemetry` (archiwum `.godot/phone-telemetry-20261003.tar`).
Raport `.godot/phone_report.json` rozpoznaje jeden zakończony log `source=playtest`,
bez uszkodzonych plików i obciętych zdarzeń: porażka na etapie 4, `mini_boss:slam`,
starter Lightning Bolt, kontrakt standard, Ascension 0, MEDIUM/cap 50.
Walki: 189,882 s; czas aplikacji: 297,508 s; pierwsza decyzja: 17,520 s;
oczekiwanie na spawn: 0,438 s. To pojedyncza próbka sprzed aktualizacji, nie dowód
pięciu kolejnych runów ani balansu 50–100 runów. Wersja starego APK nie została związana
z konkretnym hashem, dlatego nie mieszać tej próbki bezwarunkowo z nowym buildem.

Aktualizacja `adb install -r` zakończyła się sukcesem. SHA-256 zainstalowanego APK
odpowiada powyższemu plikowi. Sumy kontrolne istniejącego `meta_progression.json` i logu
pozostały identyczne przed/po instalacji. Nie odinstalowano gry ani nie czyszczono danych.
Nowe APK uruchomiono na telefonie: sprawdzono menu, Unlocks, starter Lightning Bolt,
dwie pełne walki, ich checkpointy, nagrody i przejście do trzeciego etapu. Była to kontrola
automatyczna przez ADB, nie ukończony run ani ludzki playtest balansu.

## Obserwacje automatycznej próby i strzałki testowe

- Unlocks: gest `(250,1700) → (250,900)` rozpoczęty na karcie nie przewijał listy;
  gest `(535,1700) → (535,900)` w szczelinie między kolumnami przewijał ją.
  Zrzuty: `.godot/phone-unlocks-{top,card-swipe,gap-swipe}.png`.
  Nieinteraktywne karty `PanelContainer` nie przepuszczają gestu do scrolla;
  problem odtworzono, ale nie naprawiono w zmianie sterowania.
- FIELD COMPILATION przy 35% i 70% walki zatrzymuje akcję bez zapowiedzi.
  Dotyczy tymczasowego override'u skilla, nie pasywki na cały run.
  Pierwszy ekran zapisano w `.godot/phone-run1-checkpoint.png`.
  Zmiana prezentacji pozostaje do uzgodnienia; nie zmieniono czasu ani balansu etapów.
- Automatyczny run `aefc20edecd62d0e906d10ca` przerwano w trakcie trzeciego etapu
  na aktualizację APK. Snapshot `.godot/phone-automation-20261003/telemetry`
  zachowuje surowe pliki; zapisany log ma `in_progress`, 136,548 s walk i pierwszą
  decyzję po 17,530 s. Snapshot nie obejmuje wszystkich zdarzeń trzeciej walki.
  Gra oznacza także wejścia ADB jako `source=playtest`: ten ID należy wyłączyć
  z ludzkiego zbioru cadence/win-rate. Nie zmieniano surowego logu na telefonie.
- Próba RESUME po aktualizacji ujawniła błąd `StageTree.visit`: modyfikatory po JSON
  są nietypowanym `Array`, a `StageData.modifiers` wymaga `Array[String]`.
  Dalej `begin_stage` otrzymuje null; na telefonie zostaje szary ekran.
  Błąd z logcat procesu gry nie jest naprawiony w zmianie strzałek. Dotychczasowe
  testy save/resume nie dowodzą poprawnego wejścia do kolejnego węzła po odczycie JSON.

Na prośbę użytkownika dodano cztery duże przyciski przytrzymania w lewym dolnym rogu.
`TEST ARROWS: ON/OFF` przełącza je i oryginalny joystick. Androidowy preset optuje
do `phone_test_controls`; kontrolki są dodatkowo blokowane w release przez
`OS.is_debug_build()`. Zwykłe uruchomienie bez tego feature'u nie dodaje ich do UI.
Nie ma god-mode, heal ani skip. Pauza, utrata focusu i wyłączenie strzałek zerują ruch.

APK strzałek: `builds/SyntaxBreaker-test-arrows.apk`, SHA-256
`DF53128D2586149B869601A1FBDA621C270C9BB9BFD877E89BFC4D581391D8B4`.
Aktualizacja `adb install -r` zakończyła się sukcesem; hash zainstalowanego `base.apk`
jest identyczny. Na telefonie sprawdzono widoczność czterech kontrolek, ruch w prawo,
ruch w lewo po wznowieniu z checkpointu i schowanie strzałek przez `TEST ARROWS: OFF`.
Zrzuty `.godot/phone-test-arrows.png`, `phone-test-arrows-right.png` i
`phone-test-arrows-off.png` pokazują te stany. Drugi automatyczny ID
`a240225f718b22b4519980ec` (Fireball) również wyłączyć z ludzkiego zbioru.
Jego snapshot `.godot/phone-arrows-check-20261003/telemetry` zawiera zakończony
pierwszy etap: 59,432 s walki, HP 100, pierwsza decyzja 17,523 s; w tym wcześniejszym
snapshocie run miał `in_progress`. Później dokończono go do naturalnej porażki (poniżej).
17 natywnych regresji i smoke 300 klatek przeszły. `test_controls_native` obejmuje
rzeczywiste wejście przez viewport: przytrzymaj → pauza → puść w pauzie → wznowienie
→ pierwsze nowe przytrzymanie. Test ten wykrył i potwierdził poprawkę stanu przycisku.
Starsze testy `tests/test_*.gd` wymagają GUT, którego nie ma w checkout; nie uruchomiono ich.
Eksport podpisano i zweryfikowano, bez błędów skryptów; pozostają wcześniejsze ostrzeżenia
środowiskowe dotyczące cache/settings, certyfikatów, ikony oraz build-tools.

## Dwie zakończone próby ADB na APK ze strzałkami

Na życzenie użytkownika kontynuowano wyłącznie testy telefonu; proponowaną poprawkę
wznowienia odłożono. Nie zmieniano kodu, balansu, zapisów ani ustawień urządzenia.
Obie próby zakończyły się naturalną porażką na etapie 5/10, bez god-mode/skip.
To zakończone runy automatyczne, nie przejście dziesięciu etapów ani ludzkie playtesty.

| ID / starter | Walki | Pierwsza decyzja | Śmierć | Gold earned / spent / remaining |
| --- | --- | --- | --- | --- |
| `a240225f718b22b4519980ec` / Fireball | 136,997 s | 17,523 s | `burning_boss:wall` | 105 / 0 / 135 |
| `74bd602d39df3d4eb7156e10` / Lightning Bolt | 157,081 s | 17,527 s | `burning_boss:wedge` | 94,25 / 27 / 97,25 |

Surowy snapshot: `.godot/phone-arrows-two-ended-20261003/files/telemetry`, archiwum
`.godot/phone-arrows-two-ended-20261003.tar`. Zrzuty wyników:
`.godot/phone-run2-defeat.png` i `.godot/phone-run3-defeat.png`.
W obu JSON `status=death`, `dropped_events=0`; surowe `source=playtest` nie rozpoznaje ADB.
Wyłączyć wszystkie trzy automatyczne ID (także wcześniejszy `aefc20edecd62d0e906d10ca`)
z ludzkiego zbioru. Nie przerabiano surowych logów na telefonie.

Sprawdzono ruch czterema strzałkami i powrót do ruchu po checkpointach, wybór drugiego
skilla, Treasure → support → mapa oraz Elite → nagroda → mapa. W drugiej próbie
Shop odjął 12 gold za Glass Cannon i 15 za Blade Spin (122,75 → 95,75; HUD zaokrągla
w dół). Glass Cannon przypisano do Lightning Bolt; Skill Manager pokazał trzy skille
i dwa supporty tego skilla (Faster Casting + Glass Cannon), a powrót do sklepu działał.
Zakupy i gameplay mogą normalnie zmieniać profil unlocków; nie czyszczono danych.
W pierwszej próbie gest trwający przy zakończeniu elity wybrał Thick Skin w nowym
ekranie nagrody — telemetria potwierdza wybór, ale nie traktować go jako oceny oferty.
Elita drugiej próby skończyła się po zabiciu budżetu przeciwników, przed checkpointem 70%.

Frame samples: 8190 / 9387; klatki >33 ms: 4 / 5. To pomiar delty podczas walki,
nie profil CPU/GPU ani dowód wydajności słabszego telefonu. Opóźnienia zrzut → decyzja
ograniczają ocenę telegraphów i trudności. W drugim runie boss contact odebrał 42 HP
dwa razy w odstępie około 0,517 s, potem wedge odebrał pozostałe 16 HP; nie stroić
obrażeń na podstawie takiego zdalnego wejścia. Nie nagrano ciągłego wideo śmierci.
Logcat ograniczony do bieżącego procesu gry (PID 13762) zapisano w
`.godot/phone-arrows-ended-process-logcat.txt`; w tym buforze brak SCRIPT ERROR,
Parse Error i Exception. Nie dowodzi to 99% crash-free ani poprawnego resume.

Dodatkowo znaleziono błąd Best Combo: HUD elity pokazał 32, podsumowanie/log drugiego
runu pokazuje 2. Arena tworzy nowy ComboTracker, a `_on_enemy_killed` wpisuje etapowe
`_best_combo` bez porównania z rekordem całego runu. Błąd zapisano, nie naprawiono.
Unlocks scroll, niezapowiedziane checkpointy i resume również pozostają otwarte.
Telefon po dwóch próbach pozostawiono w menu, bez aktywnej walki ani porzuconego runu;
zrzut `.godot/phone-arrows-after-two-runs-menu.png`.

## Połączenie

Najprościej: USB, włączone debugowanie USB i zaakceptowany klucz komputera na telefonie.
Alternatywa Android 11+: komputer i telefon w tej samej sieci Wi-Fi, na telefonie
Opcje programisty → Debugowanie bezprzewodowe → Sparuj urządzenie kodem.
Telefon wyświetla kod oraz IP i port parowania. Komputer nie generuje tego kodu.
Port połączenia na głównym ekranie debugowania może być inny niż port parowania.
[Dokumentacja Android ADB](https://developer.android.com/tools/adb).

```powershell
$adb = 'C:\Users\Kamil\AppData\Local\Android\Sdk\platform-tools\adb.exe'
& $adb pair '<IP>:<PORT_PAROWANIA>'
# Kod wpisuje się dopiero na wezwanie adb.
& $adb connect '<IP>:<PORT_POLACZENIA>'
& $adb devices
```

Nie wpisywać przykładowych placeholderów dosłownie. Nie instalować automatycznie na
nieznanym urządzeniu. Instalacja/aktualizacja na wskazanym telefonie wymaga zgody właściciela;
przy niezgodnym podpisie nie odinstalowywać starej gry ani nie czyścić danych bez zgody.
APK można też przekazać właścicielowi do ręcznej instalacji.

## Kolejność prób

1. Jeden smoke: menu, starter common, pierwszy etap, dotyk oznaczeń HUD, checkpoint,
   nagroda, mapa, zapis/wznowienie i koniec runu. Potwierdzić lokalny JSON telemetrii.
2. Pięć kolejnych pełnych runów bez pomijania niekorzystnych wyników. Zapisać ID i nagrania;
   zmierzyć pierwszą decyzję, przerwy, oczekiwanie na spawn i pełny czas. Nie zmieniać
   duration etapów przed tym pomiarem. Porażek nie usuwać ze zbioru.
3. Czytelność 1080×1920 i na słabszym telefonie: charger, caster, shield, splitter,
   Trail/Nova oraz każdy boss regionalny i faza finałowa. Zarejestrować śmierci i sprawdzić
   ostrzeżenie przed trafieniem, sylwetkę, bezpieczną drogę oraz źródło w podsumowaniu.
4. Wydajność słabszego telefonu przy LOW/capie 40: intensywne walki, miny/totemy,
   DoT i wielopociskowe buildy. Zebrać frame times oraz profiler CPU/GPU. Odnotować
   model telefonu, temperaturę, preset i nagranie poza anonimowym JSON gry.
5. Zbiór 50–100 realnych runów: starter, region, Ascension, kontrakt, preset i etap nauki
   zasad. Nie mieszać debug god-mode/skip z oceną win-rate. Ocenić trzy realnie używane
   archetypy na starter, pick-rate przy porównywalnej dostępności, win-rate 25–45%,
   wydatki i saldo na akt oraz różnicę LOW/HIGH. Dopiero wtedy stroić ekonomię/walkę.

Log nie zastępuje nagrania ani oceny jakości decyzji. Nieukończony JSON sam w sobie nie
dowodzi crasha; crash-free 99%+ wymaga osobnego rejestru sesji i dowodów awarii.
Codzienny seed/historia pozostają odłożone do stabilnego podstawowego balansu.

## Analiza

Po skopiowaniu JSON z telefonu do osobnego katalogu wejściowego:

```powershell
& 'D:\Pobrane\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' `
  --headless --path . --scene res://tests/telemetry_report.tscn `
  --log-file .godot/phone_report.log -- `
  --directory=res://.godot/phone-capture-20261003/telemetry --output=res://.godot/phone_report.json `
  --min-runs=50 --require-cadence
```

Raport nie zmienia logów wejściowych. Kod 2 oznacza niespełnione minimum/gate liczbowy,
nie błąd pozwalający pominąć wymaganie. Synthetic nie liczy się do 50 realnych runów.
Szczegóły i ograniczenia: [telemetria](telemetry-2026-10-03.md).
